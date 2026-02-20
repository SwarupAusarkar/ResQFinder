////const functions = require('firebase-functions');
////const admin = require('admin-official');
////admin.initializeApp();
////
////exports.notifyNearbyProviders = functions.firestore
////    .document('emergency_requests/{requestId}')
////    .onCreate(async (snapshot, context) => {
////        const requestData = snapshot.data();
////        const requestId = context.params.requestId;
////
////        // 1. Get Citizen Details
////        const citizenLat = requestData.latitude;
////        const citizenLong = requestData.longitude;
////        const radiusKm = requestData.radius || 1.5; // From your screen
////
////        // 2. Fetch all "Available" Providers
////        const providersSnapshot = await admin.firestore().collection('users')
////            .where('role', '==', 'provider')
////            .where('isAvailable', '==', true)
////            .get();
////
////        const notificationPromises = [];
////
////        providersSnapshot.forEach(doc => {
////            const providerData = doc.data();
////            const fcmToken = providerData.fcmToken;
////
////            if (fcmToken) {
////                const providerLat = providerData.latitude;
////                const providerLong = providerData.longitude;
////
////                // 3. Distance Calculation (Haversine Formula)
////                const distance = calculateDistance(citizenLat, citizenLong, providerLat, providerLong);
////
////                if (distance <= radiusKm) {
////                    const payload = {
////                        notification: {
////                            title: `🚨 EMERGENCY: ${requestData.itemName}`,
////                            body: `${requestData.requesterName} needs help ${distance.toFixed(1)}km away at ${requestData.locationName}`,
////                        },
////                        data: {
////                            requestId: requestId,
////                            click_action: "FLUTTER_NOTIFICATION_CLICK",
////                            type: "emergency_broadcast",
////                            distance: distance.toString()
////                        }
////                    };
////                    notificationPromises.push(admin.messaging().sendToDevice(fcmToken, payload));
////                }
////            }
////        });
////
////        return Promise.all(notificationPromises);
////    });
////
////// Helper: Haversine distance formula
////function calculateDistance(lat1, lon1, lat2, lon2) {
////    final distanceInMeters = Geolocator.distanceBetween(
////                    lat1,
////                   lon1,
////                   lat2,
////                    lon2,
////                  );
////                  return (distanceInMeters / 1000);
//const functions = require('firebase-functions');
//const admin = require('firebase-admin');
//
//// Initialize admin SDK
//admin.initializeApp();
//
///**
// * MAIN FUNCTION: Send notifications when emergency request is created
// * Uses FCM V1 API (Legacy API deprecated March 2024)
// */
//exports.onEmergencyRequestCreated = functions.firestore
//  .document('emergency_requests/{requestId}')
//  .onCreate(async (snap, context) => {
//    const requestData = snap.data();
//    const requestId = context.params.requestId;
//
//    console.log('🚨 New emergency request:', requestId);
//    console.log('📍 Location:', requestData.latitude, requestData.longitude);
//    console.log('🎯 Radius:', requestData.radius, 'km');
//
//    // Convert radius from km to degrees (approximate)
//    const radiusDegrees = (requestData.radius || 5) / 111;
//
//    try {
//      // Get nearby providers
//      const providersSnapshot = await admin.firestore()
//        .collection('users')
//        .where('userType', '==', 'provider')
//        .where('isAvailable', '==', true)
//        .where('latitude', '>=', requestData.latitude - radiusDegrees)
//        .where('latitude', '<=', requestData.latitude + radiusDegrees)
//        .get();
//
//      console.log(`🔍 Found ${providersSnapshot.size} potential providers`);
//
//      const notifications = [];
//
//      for (const providerDoc of providersSnapshot.docs) {
//        const providerData = providerDoc.data();
//
//        // Check longitude is within range
//        const lonDiff = Math.abs(providerData.longitude - requestData.longitude);
//        if (lonDiff > radiusDegrees) continue;
//
//        // Calculate actual distance (Haversine)
//        const distance = calculateDistance(
//          requestData.latitude,
//          requestData.longitude,
//          providerData.latitude,
//          providerData.longitude
//        );
//
//        console.log(`📏 Provider ${providerDoc.id} is ${distance.toFixed(2)}km away`);
//
//        if (distance <= requestData.radius && providerData.fcmToken) {
//          // FCM V1 API message format
//          const message = {
//            token: providerData.fcmToken,
//            notification: {
//              title: '🚨 EMERGENCY REQUEST',
//              body: `${requestData.requesterName} needs ${requestData.itemQuantity} ${requestData.itemUnit} of ${requestData.itemName} (${distance.toFixed(1)}km away)`,
//            },
//            data: {
//              requestId: requestId,
//              type: 'emergency_request',
//              itemName: requestData.itemName || '',
//              itemQuantity: String(requestData.itemQuantity || 0),
//              itemUnit: requestData.itemUnit || '',
//              distance: String(distance.toFixed(1)),
//              latitude: String(requestData.latitude),
//              longitude: String(requestData.longitude),
//              requesterName: requestData.requesterName || 'Someone',
//              locationName: requestData.locationName || 'Unknown location',
//            },
//            android: {
//              priority: 'high',
//              notification: {
//                channelId: 'emergency_channel_id',
//                priority: 'high',
//                sound: 'default',
//                color: '#00897B',
//                defaultSound: true,
//                defaultVibrateTimings: true,
//              },
//            },
//            apns: {
//              headers: {
//                'apns-priority': '10',
//              },
//              payload: {
//                aps: {
//                  sound: 'default',
//                  badge: 1,
//                  contentAvailable: true,
//                },
//              },
//            },
//          };
//
//          // Send notification using V1 API
//          notifications.push(
//            admin.messaging().send(message)
//              .then(response => {
//                console.log('✅ Sent to', providerDoc.id, ':', response);
//                return { success: true, providerId: providerDoc.id };
//              })
//              .catch(error => {
//                console.error('❌ Failed to send to', providerDoc.id, ':', error);
//
//                // Handle invalid token
//                if (error.code === 'messaging/invalid-registration-token' ||
//                    error.code === 'messaging/registration-token-not-registered') {
//                  console.log('🗑️ Removing invalid token for', providerDoc.id);
//                  return admin.firestore()
//                    .collection('users')
//                    .doc(providerDoc.id)
//                    .update({ fcmToken: admin.firestore.FieldValue.delete() });
//                }
//                return { success: false, providerId: providerDoc.id, error: error.message };
//              })
//          );
//        }
//      }
//
//      const results = await Promise.all(notifications);
//      const successCount = results.filter(r => r.success).length;
//
//      console.log(`✅ Sent ${successCount}/${results.length} notifications`);
//
//      return { success: true, notificationsSent: successCount };
//    } catch (error) {
//      console.error('❌ Error in notification function:', error);
//      return { success: false, error: error.message };
//    }
//  });
//
///**
// * Helper: Calculate distance between two points using Haversine formula
// */
//function calculateDistance(lat1, lon1, lat2, lon2) {
//final distanceInMeters = Geolocator.distanceBetween(
//                    lat1,
//                   lon1,
//                   lat2,
//                    lon2,
//                  );
//                  return (distanceInMeters / 1000)
//}
//
//function toRad(degrees) {
//  return degrees * (Math.PI / 180);
//}
///**
// * Notify provider when inventory needs update
// * Triggers when: Provider's inventory item quantity is low
// */
//exports.notifyInventoryUpdate = functions.firestore
//  .document('users/{providerId}/inventory/{itemId}')
//  .onUpdate(async (change, context) => {
//    const newData = change.after.data();
//    const oldData = change.before.data();
//    const providerId = context.params.providerId;
//
//    // Only notify if quantity decreased below threshold
//    if (newData.quantity < 5 && oldData.quantity >= 5) {
//      try {
//        // Get provider FCM token
//        const providerDoc = await admin.firestore()
//          .collection('users')
//          .doc(providerId)
//          .get();
//
//        const providerData = providerDoc.data();
//
//        if (!providerData || !providerData.fcmToken) {
//          console.log('No FCM token for provider:', providerId);
//          return null;
//        }
//
//        // FCM V1 message
//        const message = {
//          token: providerData.fcmToken,
//          notification: {
//            title: '⚠️ Low Inventory Alert',
//            body: `${newData.name} stock is low (${newData.quantity} ${newData.unit} remaining). Update your inventory!`,
//          },
//          data: {
//            type: 'inventory_update',
//            itemId: context.params.itemId,
//            itemName: newData.name || '',
//            quantity: String(newData.quantity || 0),
//            unit: newData.unit || '',
//            redirectTo: 'manage-inventory', // Navigation target
//          },
//          android: {
//            priority: 'high',
//            notification: {
//              channelId: 'emergency_channel_id',
//              priority: 'default',
//              sound: 'default',
//              color: '#FF9800',
//            },
//          },
//        };
//
//        const response = await admin.messaging().send(message);
//        console.log('✅ Inventory notification sent:', response);
//
//        return { success: true, messageId: response };
//      } catch (error) {
//        console.error('❌ Error sending inventory notification:', error);
//        return { success: false, error: error.message };
//      }
//    }
//
//    return null;
//  });
//  /**
//   * Notify requester when provider sends an offer
//   * Triggers when: New offer added to emergency_requests.offers array
//   */
//  exports.notifyOfferReceived = functions.firestore
//    .document('emergency_requests/{requestId}')
//    .onUpdate(async (change, context) => {
//      const newData = change.after.data();
//      const oldData = change.before.data();
//      const requestId = context.params.requestId;
//
//      // Check if new offers were added
//      const newOffers = newData.offers || [];
//      const oldOffers = oldData.offers || [];
//
//      if (newOffers.length > oldOffers.length) {
//        // Find the new offer(s)
//        const newOffersList = newOffers.filter(newOffer =>
//          !oldOffers.some(oldOffer => oldOffer.providerId === newOffer.providerId)
//        );
//
//        try {
//          // Get requester FCM token
//          const requesterDoc = await admin.firestore()
//            .collection('users')
//            .doc(newData.requesterId)
//            .get();
//
//          const requesterData = requesterDoc.data();
//
//          if (!requesterData || !requesterData.fcmToken) {
//            console.log('No FCM token for requester:', newData.requesterId);
//            return null;
//          }
//
//          // Send notification for each new offer
//          const notifications = newOffersList.map(offer => {
//            const message = {
//              token: requesterData.fcmToken,
//              notification: {
//                title: '🤝 New Offer Received!',
//                body: `${offer.providerName} wants to help with your ${newData.itemName} request. Review now!`,
//              },
//              data: {
//                type: 'offer_received',
//                requestId: requestId,
//                providerId: offer.providerId || '',
//                providerName: offer.providerName || '',
//                itemName: newData.itemName || '',
//                offerCount: String(newOffers.filter(o => o.status === 'waiting').length),
//                redirectTo: 'offer-approval', // Navigation target
//              },
//              android: {
//                priority: 'high',
//                notification: {
//                  channelId: 'emergency_channel_id',
//                  priority: 'high',
//                  sound: 'default',
//                  color: '#00897B',
//                },
//              },
//            };
//
//            return admin.messaging().send(message);
//          });
//
//          const results = await Promise.all(notifications);
//          console.log(`✅ Sent ${results.length} offer notification(s)`);
//
//          return { success: true, count: results.length };
//        } catch (error) {
//          console.error('❌ Error sending offer notification:', error);
//          return { success: false, error: error.message };
//        }
//      }
//
//      return null;
//    });
//    /**
//     * Notify only the approved provider when requester confirms
//     * Triggers when: confirmedProviderId is set and status becomes 'confirmed'
//     */
//    exports.notifyProviderApproved = functions.firestore
//      .document('emergency_requests/{requestId}')
//      .onUpdate(async (change, context) => {
//        const newData = change.after.data();
//        const oldData = change.before.data();
//        const requestId = context.params.requestId;
//
//        // Check if request was just confirmed
//        const wasConfirmed = oldData.status !== 'confirmed' && newData.status === 'confirmed';
//
//        if (wasConfirmed && newData.confirmedProviderId) {
//          try {
//            // Get ONLY the confirmed provider's FCM token
//            const providerDoc = await admin.firestore()
//              .collection('users')
//              .doc(newData.confirmedProviderId)
//              .get();
//
//            const providerData = providerDoc.data();
//
//            if (!providerData || !providerData.fcmToken) {
//              console.log('No FCM token for confirmed provider:', newData.confirmedProviderId);
//              return null;
//            }
//
//            // FCM V1 message
//            const message = {
//              token: providerData.fcmToken,
//              notification: {
//                title: '🎉 You\'re Selected!',
//                body: `${newData.requesterName} approved your offer for ${newData.itemName}. Head to their location now!`,
//              },
//              data: {
//                type: 'offer_approved',
//                requestId: requestId,
//                itemName: newData.itemName || '',
//                itemQuantity: String(newData.itemQuantity || 0),
//                itemUnit: newData.itemUnit || '',
//                requesterName: newData.requesterName || '',
//                locationName: newData.locationName || '',
//                latitude: String(newData.latitude || 0),
//                longitude: String(newData.longitude || 0),
//                redirectTo: 'provider-dashboard', // Navigation target
//              },
//              android: {
//                priority: 'high',
//                notification: {
//                  channelId: 'emergency_channel_id',
//                  priority: 'max',
//                  sound: 'default',
//                  color: '#4CAF50',
//                },
//              },
//            };
//
//            const response = await admin.messaging().send(message);
//            console.log('✅ Approval notification sent to winner:', response);
//
//            return { success: true, messageId: response };
//          } catch (error) {
//            console.error('❌ Error sending approval notification:', error);
//            return { success: false, error: error.message };
//          }
//        }
//
//        return null;
//      });
//      /**
//       * Notify requester with verification code when generated
//       * Triggers when: verificationCode is set (after requester approves provider)
//       */
//      exports.notifyVerificationCode = functions.firestore
//        .document('emergency_requests/{requestId}')
//        .onUpdate(async (change, context) => {
//          const newData = change.after.data();
//          const oldData = change.before.data();
//          const requestId = context.params.requestId;
//
//          // Check if verification code was just generated
//          const codeGenerated = !oldData.verificationCode && newData.verificationCode;
//
//          if (codeGenerated) {
//            try {
//              // Get requester FCM token
//              const requesterDoc = await admin.firestore()
//                .collection('users')
//                .doc(newData.requesterId)
//                .get();
//
//              const requesterData = requesterDoc.data();
//
//              if (!requesterData || !requesterData.fcmToken) {
//                console.log('No FCM token for requester:', newData.requesterId);
//                return null;
//              }
//
//              // Get confirmed provider info
//              let providerName = 'Provider';
//              if (newData.confirmedProviderId) {
//                const providerDoc = await admin.firestore()
//                  .collection('users')
//                  .doc(newData.confirmedProviderId)
//                  .get();
//                providerName = providerDoc.data()?.fullName || 'Provider';
//              }
//
//              // FCM V1 message
//              const message = {
//                token: requesterData.fcmToken,
//                notification: {
//                  title: '🔐 Verification Code Generated',
//                  body: `Your code is ${newData.verificationCode}. Share this with ${providerName} when they arrive.`,
//                },
//                data: {
//                  type: 'verification_code',
//                  requestId: requestId,
//                  verificationCode: newData.verificationCode || '',
//                  providerName: providerName,
//                  itemName: newData.itemName || '',
//                  redirectTo: 'offer-approval', // Navigation target - to see the code
//                },
//                android: {
//                  priority: 'high',
//                  notification: {
//                    channelId: 'emergency_channel_id',
//                    priority: 'high',
//                    sound: 'default',
//                    color: '#2196F3',
//                  },
//                },
//              };
//
//              const response = await admin.messaging().send(message);
//              console.log('✅ Verification code notification sent:', response);
//
//              return { success: true, messageId: response };
//            } catch (error) {
//              console.error('❌ Error sending verification notification:', error);
//              return { success: false, error: error.message };
//            }
//          }
//
//          return null;
//        });
///**
// * Optional: Cleanup old requests (run daily)
// */
//exports.cleanupOldRequests = functions.pubsub
//  .schedule('0 2 * * *') // Run at 2 AM daily
//  .timeZone('Asia/Kolkata')
//  .onRun(async (context) => {
//    const sevenDaysAgo = new Date();
//    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
//
//    const snapshot = await admin.firestore()
//      .collection('emergency_requests')
//      .where('timestamp', '<', sevenDaysAgo)
//      .where('status', '==', 'completed')
//      .get();
//
//    const batch = admin.firestore().batch();
//    snapshot.docs.forEach((doc) => {
//      batch.delete(doc.ref);
//    });
//
//    await batch.commit();
//    console.log(`🗑️ Deleted ${snapshot.size} old completed requests`);
//
//    return null;
//  });

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin SDK
admin.initializeApp();

/**
 * MAIN FUNCTION: Send notifications when emergency request is created
 */
exports.onEmergencyRequestCreated = functions.firestore
  .document('emergency_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();
    const requestId = context.params.requestId;

    console.log('🚨 New emergency request:', requestId);

    const radiusDegrees = (requestData.radius || 5) / 111;

    try {
      // Get nearby providers
      const providersSnapshot = await admin.firestore()
        .collection('providers')
        .where('isAvailable', '==', true)
        .where('latitude', '>=', requestData.latitude - radiusDegrees)
        .where('latitude', '<=', requestData.latitude + radiusDegrees)
        .get();

      const notifications = [];

      for (const providerDoc of providersSnapshot.docs) {
        const providerData = providerDoc.data();
        const lonDiff = Math.abs(providerData.longitude - requestData.longitude);
        if (lonDiff > radiusDegrees) continue;

        const distance = calculateDistance(
          requestData.latitude,
          requestData.longitude,
          providerData.latitude,
          providerData.longitude
        );

        if (distance <= requestData.radius && providerData.fcmToken) {
          const message = {
            token: providerData.fcmToken,
            notification: {
              title: '🚨 EMERGENCY REQUEST',
              body: `${requestData.requesterName} needs ${requestData.itemQuantity} ${requestData.itemUnit} of ${requestData.itemName} (${distance.toFixed(1)}km away)`,
            },
            data: {
              type: 'emergency_request',
              requestId,
              itemName: requestData.itemName || '',
              itemQuantity: String(requestData.itemQuantity || 0),
              itemUnit: requestData.itemUnit || '',
              distance: String(distance.toFixed(1)),
              latitude: String(requestData.latitude),
              longitude: String(requestData.longitude),
              requesterName: requestData.requesterName || 'Someone',
              locationName: requestData.locationName || 'Unknown location',
            },
            android: { priority: 'high' },
            apns: { headers: { 'apns-priority': '10' } },
          };

          notifications.push(admin.messaging().send(message));
        }
      }

      await Promise.all(notifications);
      return { success: true, notificationsSent: notifications.length };
    } catch (error) {
      console.error('❌ Error in notification function:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Inventory update notifications for providers
 */
exports.notifyInventoryUpdate = functions.firestore
  .document('providers/{providerId}/inventory/{itemId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const providerId = context.params.providerId;

    if (newData.quantity < 5 && oldData.quantity >= 5) {
      const providerDoc = await admin.firestore()
        .collection('providers')
        .doc(providerId)
        .get();

      const providerData = providerDoc.data();
      if (!providerData?.fcmToken) return null;

      const message = {
        token: providerData.fcmToken,
        notification: {
          title: '⚠️ Low Inventory Alert',
          body: `${newData.name} stock is low (${newData.quantity} ${newData.unit} remaining).`,
        },
        data: { type: 'inventory_update', itemId: context.params.itemId },
      };

      return admin.messaging().send(message);
    }
    return null;
  });

/**
 * Notify requester when provider sends an offer
 */
exports.notifyOfferReceived = functions.firestore
  .document('emergency_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const requestId = context.params.requestId;

    const newOffers = newData.offers || [];
    const oldOffers = oldData.offers || [];

    if (newOffers.length > oldOffers.length) {
      const requesterDoc = await admin.firestore()
        .collection('requesters')
        .doc(newData.requesterId)
        .get();

      const requesterData = requesterDoc.data();
      if (!requesterData?.fcmToken) return null;

      const message = {
        token: requesterData.fcmToken,
        notification: {
          title: '🤝 New Offer Received!',
          body: `You have a new offer for ${newData.itemName}.`,
        },
        data: { type: 'offer_received', requestId },
      };

      return admin.messaging().send(message);
    }
    return null;
  });

/**
 * Notify provider when approved
 */
exports.notifyProviderApproved = functions.firestore
  .document('emergency_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (oldData.status !== 'confirmed' && newData.status === 'confirmed') {
      const providerDoc = await admin.firestore()
        .collection('providers')
        .doc(newData.confirmedProviderId)
        .get();

      const providerData = providerDoc.data();
      if (!providerData?.fcmToken) return null;

      const message = {
        token: providerData.fcmToken,
        notification: {
          title: '🎉 You\'re Selected!',
          body: `${newData.requesterName} approved your offer.`,
        },
        data: { type: 'offer_approved', requestId: context.params.requestId },
      };

      return admin.messaging().send(message);
    }
    return null;
  });

/**
 * Notify requester with verification code
 */
exports.notifyVerificationCode = functions.firestore
  .document('emergency_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!oldData.verificationCode && newData.verificationCode) {
      const requesterDoc = await admin.firestore()
        .collection('requesters')
        .doc(newData.requesterId)
        .get();

      const requesterData = requesterDoc.data();
      if (!requesterData?.fcmToken) return null;

      const message = {
        token: requesterData.fcmToken,
        notification: {
          title: '🔐 Verification Code Generated',
          body: `Your code is ${newData.verificationCode}.`,
        },
        data: { type: 'verification_code', requestId: context.params.requestId },
      };

      return admin.messaging().send(message);
    }
    return null;
  });

/**
 * Cleanup old requests
 */
exports.cleanupOldRequests = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('Asia/Kolkata')
  .onRun(async () => {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const snapshot = await admin.firestore()
      .collection('emergency_requests')
      .where('timestamp', '<', sevenDaysAgo)
      .where('status', '==', 'completed')
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();

    console.log(`🗑️ Deleted ${snapshot.size} old completed requests`);
    return null;
  });

/**
 * Helper: Calculate distance (Haversine)
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
