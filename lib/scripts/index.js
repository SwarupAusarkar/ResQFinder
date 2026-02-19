//const functions = require('firebase-functions');
//const admin = require('admin-official');
//admin.initializeApp();
//
//exports.notifyNearbyProviders = functions.firestore
//    .document('emergency_requests/{requestId}')
//    .onCreate(async (snapshot, context) => {
//        const requestData = snapshot.data();
//        const requestId = context.params.requestId;
//
//        // 1. Get Citizen Details
//        const citizenLat = requestData.latitude;
//        const citizenLong = requestData.longitude;
//        const radiusKm = requestData.radius || 1.5; // From your screen
//
//        // 2. Fetch all "Available" Providers
//        const providersSnapshot = await admin.firestore().collection('users')
//            .where('role', '==', 'provider')
//            .where('isAvailable', '==', true)
//            .get();
//
//        const notificationPromises = [];
//
//        providersSnapshot.forEach(doc => {
//            const providerData = doc.data();
//            const fcmToken = providerData.fcmToken;
//
//            if (fcmToken) {
//                const providerLat = providerData.latitude;
//                const providerLong = providerData.longitude;
//
//                // 3. Distance Calculation (Haversine Formula)
//                const distance = calculateDistance(citizenLat, citizenLong, providerLat, providerLong);
//
//                if (distance <= radiusKm) {
//                    const payload = {
//                        notification: {
//                            title: `🚨 EMERGENCY: ${requestData.itemName}`,
//                            body: `${requestData.requesterName} needs help ${distance.toFixed(1)}km away at ${requestData.locationName}`,
//                        },
//                        data: {
//                            requestId: requestId,
//                            click_action: "FLUTTER_NOTIFICATION_CLICK",
//                            type: "emergency_broadcast",
//                            distance: distance.toString()
//                        }
//                    };
//                    notificationPromises.push(admin.messaging().sendToDevice(fcmToken, payload));
//                }
//            }
//        });
//
//        return Promise.all(notificationPromises);
//    });
//
//// Helper: Haversine distance formula
//function calculateDistance(lat1, lon1, lat2, lon2) {
//    final distanceInMeters = Geolocator.distanceBetween(
//                    lat1,
//                   lon1,
//                   lat2,
//                    lon2,
//                  );
//                  return (distanceInMeters / 1000);
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin SDK
admin.initializeApp();

/**
 * MAIN FUNCTION: Send notifications when emergency request is created
 * Uses FCM V1 API (Legacy API deprecated March 2024)
 */
exports.onEmergencyRequestCreated = functions.firestore
  .document('emergency_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();
    const requestId = context.params.requestId;

    console.log('🚨 New emergency request:', requestId);
    console.log('📍 Location:', requestData.latitude, requestData.longitude);
    console.log('🎯 Radius:', requestData.radius, 'km');

    // Convert radius from km to degrees (approximate)
    const radiusDegrees = (requestData.radius || 5) / 111;

    try {
      // Get nearby providers
      const providersSnapshot = await admin.firestore()
        .collection('users')
        .where('userType', '==', 'provider')
        .where('isAvailable', '==', true)
        .where('latitude', '>=', requestData.latitude - radiusDegrees)
        .where('latitude', '<=', requestData.latitude + radiusDegrees)
        .get();

      console.log(`🔍 Found ${providersSnapshot.size} potential providers`);

      const notifications = [];

      for (const providerDoc of providersSnapshot.docs) {
        const providerData = providerDoc.data();

        // Check longitude is within range
        const lonDiff = Math.abs(providerData.longitude - requestData.longitude);
        if (lonDiff > radiusDegrees) continue;

        // Calculate actual distance (Haversine)
        const distance = calculateDistance(
          requestData.latitude,
          requestData.longitude,
          providerData.latitude,
          providerData.longitude
        );

        console.log(`📏 Provider ${providerDoc.id} is ${distance.toFixed(2)}km away`);

        if (distance <= requestData.radius && providerData.fcmToken) {
          // FCM V1 API message format
          const message = {
            token: providerData.fcmToken,
            notification: {
              title: '🚨 EMERGENCY REQUEST',
              body: `${requestData.requesterName} needs ${requestData.itemQuantity} ${requestData.itemUnit} of ${requestData.itemName} (${distance.toFixed(1)}km away)`,
            },
            data: {
              requestId: requestId,
              type: 'emergency_request',
              itemName: requestData.itemName || '',
              itemQuantity: String(requestData.itemQuantity || 0),
              itemUnit: requestData.itemUnit || '',
              distance: String(distance.toFixed(1)),
              latitude: String(requestData.latitude),
              longitude: String(requestData.longitude),
              requesterName: requestData.requesterName || 'Someone',
              locationName: requestData.locationName || 'Unknown location',
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'emergency_channel_id',
                priority: 'high',
                sound: 'default',
                color: '#00897B',
                defaultSound: true,
                defaultVibrateTimings: true,
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
                  contentAvailable: true,
                },
              },
            },
          };

          // Send notification using V1 API
          notifications.push(
            admin.messaging().send(message)
              .then(response => {
                console.log('✅ Sent to', providerDoc.id, ':', response);
                return { success: true, providerId: providerDoc.id };
              })
              .catch(error => {
                console.error('❌ Failed to send to', providerDoc.id, ':', error);

                // Handle invalid token
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                  console.log('🗑️ Removing invalid token for', providerDoc.id);
                  return admin.firestore()
                    .collection('users')
                    .doc(providerDoc.id)
                    .update({ fcmToken: admin.firestore.FieldValue.delete() });
                }
                return { success: false, providerId: providerDoc.id, error: error.message };
              })
          );
        }
      }

      const results = await Promise.all(notifications);
      const successCount = results.filter(r => r.success).length;

      console.log(`✅ Sent ${successCount}/${results.length} notifications`);

      return { success: true, notificationsSent: successCount };
    } catch (error) {
      console.error('❌ Error in notification function:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Helper: Calculate distance between two points using Haversine formula
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
final distanceInMeters = Geolocator.distanceBetween(
                    lat1,
                   lon1,
                   lat2,
                    lon2,
                  );
                  return (distanceInMeters / 1000)
}

function toRad(degrees) {
  return degrees * (Math.PI / 180);
}

/**
 * Optional: Cleanup old requests (run daily)
 */
exports.cleanupOldRequests = functions.pubsub
  .schedule('0 2 * * *') // Run at 2 AM daily
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const snapshot = await admin.firestore()
      .collection('emergency_requests')
      .where('timestamp', '<', sevenDaysAgo)
      .where('status', '==', 'completed')
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`🗑️ Deleted ${snapshot.size} old completed requests`);

    return null;
  });