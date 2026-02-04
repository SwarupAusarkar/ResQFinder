// Firebase Cloud Functions for sending FCM notifications
// Deploy this to Firebase Functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function: Send FCM notification when a notification document is created
 * Triggered by: Firestore onCreate in /notifications collection
 */
exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();

    // Check if already sent
    if (notificationData.sent) {
      console.log('Notification already sent, skipping...');
      return null;
    }

    const fcmToken = notificationData.fcmToken;

    if (!fcmToken) {
      console.error('No FCM token found in notification document');
      return null;
    }

    // Prepare FCM message
    const message = {
      token: fcmToken,
      notification: {
        title: notificationData.title || 'New Notification',
        body: notificationData.body || 'You have a new notification',
      },
      data: {
        notificationId: context.params.notificationId,
        type: notificationData.type || 'general',
        requestId: notificationData.requestId || '',
        ...notificationData.data,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'emergency_requests_channel',
          priority: 'high',
          sound: 'default',
          color: '#FF0000',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      // Send FCM notification
      const response = await admin.messaging().send(message);
      console.log('✅ Successfully sent notification:', response);

      // Mark as sent in Firestore
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

      return response;
    } catch (error) {
      console.error('❌ Error sending notification:', error);

      // Update with error
      await snap.ref.update({
        sent: false,
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // If token is invalid, remove it from user document
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log('🗑️ Removing invalid FCM token from user');

        if (notificationData.recipientId) {
          await admin.firestore()
            .collection('users')
            .doc(notificationData.recipientId)
            .update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
        }
      }

      return null;
    }
  });

/**
 * Cloud Function: Send notification to multiple providers (batch)
 * Callable function for sending to multiple FCM tokens at once
 */
exports.sendBatchNotification = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to send notifications'
    );
  }

  const { tokens, title, body, data: notificationData } = data;

  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Tokens array is required and must not be empty'
    );
  }

  const message = {
    notification: {
      title: title || 'New Notification',
      body: body || 'You have a new notification',
    },
    data: notificationData || {},
    android: {
      priority: 'high',
      notification: {
        channelId: 'emergency_requests_channel',
        priority: 'high',
        sound: 'default',
        color: '#FF0000',
      },
    },
  };

  try {
    const response = await admin.messaging().sendMulticast({
      tokens: tokens,
      ...message,
    });

    console.log(`✅ Batch notification sent. Success: ${response.successCount}, Failed: ${response.failureCount}`);

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('❌ Error sending batch notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function: Cleanup old notifications
 * Scheduled to run daily at midnight
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 0 * * *') // Run at midnight every day
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const snapshot = await admin.firestore()
      .collection('notifications')
      .where('timestamp', '<', thirtyDaysAgo)
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`🗑️ Deleted ${snapshot.size} old notifications`);

    return null;
  });

/**
 * Cloud Function: Update user FCM token
 * Triggered when user document is updated
 */
exports.onUserUpdate = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Check if FCM token changed
    if (newData.fcmToken && newData.fcmToken !== oldData.fcmToken) {
      console.log(`✅ FCM token updated for user: ${context.params.userId}`);

      // Subscribe to relevant topics based on user type
      if (newData.userType === 'provider' && newData.type) {
        try {
          await admin.messaging().subscribeToTopic(
            newData.fcmToken,
            `providers_${newData.type}`
          );
          console.log(`✅ Subscribed to topic: providers_${newData.type}`);
        } catch (error) {
          console.error('❌ Error subscribing to topic:', error);
        }
      }
    }

    return null;
  });

/**
 * Cloud Function: Send notification when emergency request is created
 * This provides an alternative to the app-side notification sending
 */
exports.onEmergencyRequestCreated = functions.firestore
  .document('emergency_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();

    console.log('🚨 New emergency request created:', context.params.requestId);

    // Get nearby providers
    const radiusDegrees = requestData.radius / 111; // Convert km to degrees

    const providersSnapshot = await admin.firestore()
      .collection('users')
      .where('userType', '==', 'provider')
      .where('isAvailable', '==', true)
      .where('latitude', '>=', requestData.latitude - radiusDegrees)
      .where('latitude', '<=', requestData.latitude + radiusDegrees)
      .get();

    console.log(`📍 Found ${providersSnapshot.size} potential providers`);

    const notifications = [];

    for (const providerDoc of providersSnapshot.docs) {
      const providerData = providerDoc.data();

      // Check longitude and calculate distance
      if (providerData.longitude >= requestData.longitude - radiusDegrees &&
          providerData.longitude <= requestData.longitude + radiusDegrees) {

        const fcmToken = providerData.fcmToken;

        if (fcmToken) {
          notifications.push(
            admin.firestore().collection('notifications').add({
              recipientId: providerDoc.id,
              fcmToken: fcmToken,
              requestId: context.params.requestId,
              type: 'new_request',
              title: '🚨 New Emergency Request',
              body: `${requestData.requesterName} needs ${requestData.itemQuantity} ${requestData.itemUnit} of ${requestData.itemName}`,
              data: {
                requestId: context.params.requestId,
                itemName: requestData.itemName,
                itemQuantity: requestData.itemQuantity.toString(),
                itemUnit: requestData.itemUnit,
              },
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              sent: false,
            })
          );
        }
      }
    }

    await Promise.all(notifications);
    console.log(`✅ Queued ${notifications.length} notifications`);

    return null;
  });