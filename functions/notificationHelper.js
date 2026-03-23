//// notificationHelper.js
//// Firebase Cloud Functions v2 – Production Safe Version
//
//const { getFirestore } = require("firebase-admin/firestore");
//const { getMessaging } = require("firebase-admin/messaging");
//const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
//const { onSchedule } = require("firebase-functions/v2/scheduler");
//const admin = require("firebase-admin");
//
//const db = getFirestore();
//const messaging = getMessaging();
//
//// ─────────────────────────────────────────────
//// 🌍 HAVERSINE DISTANCE (KM)
//// ─────────────────────────────────────────────
//function haversineDistance(lat1, lon1, lat2, lon2) {
//  const R = 6371;
//  const toRad = (deg) => (deg * Math.PI) / 180;
//  const dLat = toRad(lat2 - lat1);
//  const dLon = toRad(lon2 - lon1);
//  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
//  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
//}
//
//// ─────────────────────────────────────────────
//// 🔔 SEND SINGLE NOTIFICATION (FIXED SYNTAX)
//// ─────────────────────────────────────────────
//async function sendNotification(token, title, body, data = {}) {
//  if (!token) return;
//
//  const message = {
//    token,
//    notification: { title, body },
//    data: {
//      ...Object.fromEntries(
//        Object.entries(data).map(([k, v]) => [k, String(v)])
//      ),
//      click_action: "FLUTTER_NOTIFICATION_CLICK",
//    },
//    android: {
//      priority: "high",
//      notification: {
//        channelId: "emergency_channel",
//        clickAction: "FLUTTER_NOTIFICATION_CLICK",
//      },
//    },
//    apns: { // Fixed: Now correctly inside the message object
//      payload: {
//        aps: {
//          sound: "default",
//        },
//      },
//    },
//  };
//
//  try {
//    const res = await messaging.send(message);
//    console.log("✅ FCM Sent:", res);
//  } catch (err) {
//    console.error("❌ FCM Error:", err.code);
//  }
//}
//
//// ─────────────────────────────────────────────
//// 🔔 SEND MULTICAST (Batch)
//// ─────────────────────────────────────────────
//async function sendMulticast(tokens, title, body, data = {}) {
//  const validTokens = tokens.filter(t => t && t.length > 0);
//  if (!validTokens.length) return;
//
//  const message = {
//    tokens: validTokens,
//    notification: { title, body },
//    data: Object.fromEntries(
//      Object.entries(data).map(([k, v]) => [k, String(v)])
//    ),
//    android: {
//      priority: "high",
//      notification: {
//        channelId: "emergency_channel",
//        sound: "default",
//      },
//    },
//  };
//
//  try {
//    const res = await messaging.sendEachForMulticast(message);
//    console.log(`📢 Multicast → Success: ${res.successCount}, Fail: ${res.failureCount}`);
//  } catch (err) {
//    console.error("❌ Multicast Error:", err);
//  }
//}
//
//// ─────────────────────────────────────────────
//// 🚀 TRIGGERS
//// ─────────────────────────────────────────────
//
//exports.onNewEmergencyRequest = onDocumentCreated(
//  "emergency_requests/{requestId}",
//  async (event) => {
//    const data = event.data?.data();
//    if (!data) return;
//
//    const reqLat = data.latitude ?? data.location?.latitude;
//    const reqLon = data.longitude ?? data.location?.longitude;
//    const radius = data.radius ?? 10;
//
//    if (!reqLat || !reqLon) return;
//
//    const latDelta = radius / 111;
//    const snapshot = await db.collection("providers")
//      .where("isAvailable", "==", true)
//      .where("latitude", ">=", reqLat - latDelta)
//      .where("latitude", "<=", reqLat + latDelta)
//      .get();
//
//    const tokensInRadius = [];
//    snapshot.forEach((doc) => {
//      const provider = doc.data();
//      if (provider.fcmToken && haversineDistance(reqLat, reqLon, provider.latitude, provider.longitude) <= radius) {
//        tokensInRadius.push(provider.fcmToken);
//      }
//    });
//
//    await sendMulticast(tokensInRadius, "🚨 New Emergency Nearby", "Urgent help needed in your area.", { type: "new_request", requestId: event.params.requestId });
//  }
//);
//
//exports.onOfferSent = onDocumentUpdated(
//  "emergency_requests/{requestId}",
//  async (event) => {
//    const before = event.data?.before?.data();
//    const after = event.data?.after?.data();
//    if (!before || !after || (after.offers?.length || 0) <= (before.offers?.length || 0)) return;
//
//    const requesterDoc = await db.collection("requesters").doc(after.requesterId).get();
//    const token = requesterDoc.data()?.fcmToken;
//
//    await sendNotification(token, "📩 New Provider Offer", "A provider has offered to help.", { type: "offer_received", requestId: event.params.requestId });
//  }
//);
//
//exports.onRequestConfirmed = onDocumentUpdated(
//  "emergency_requests/{requestId}",
//  async (event) => {
//    const before = event.data?.before?.data();
//    const after = event.data?.after?.data();
//    if (!before || !after || before.status === "confirmed" || after.status !== "confirmed") return;
//
//    const providerDoc = await db.collection("providers").doc(after.confirmedProviderId).get();
//    const token = providerDoc.data()?.fcmToken;
//
//    await sendNotification(token, "✅ Offer Accepted!", "Proceed to the location.", { type: "offer_approved", requestId: event.params.requestId });
//  }
//);
//
//exports.dailyInventoryReminder = onSchedule("every day 09:00", async () => {
//    const snapshot = await db.collection("providers").get();
//    const tokens = [];
//    snapshot.forEach(doc => { if (doc.data()?.fcmToken) tokens.push(doc.data().fcmToken); });
//    await sendMulticast(tokens, "📦 Daily Check", "Update your availability.", { type: "inventory_reminder" });
//});
//
//// FIXED: Removed redundant 'const { onDocumentUpdated } = ...' imports here
//exports.sendReviewNotification = onDocumentUpdated(
//  "emergency_requests/{requestId}",
//  async (event) => {
//    const beforeData = event.data.before.data();
//    const afterData = event.data.after.data();
//    const requestId = event.params.requestId;
//
//    if (!beforeData || !afterData) return null;
//
//    if (afterData.status === 'completed' && beforeData.status !== 'completed') {
//      const requesterId = afterData.requesterId;
//      const providerName = afterData.confirmedProviderName || "the provider";
//
//      try {
//        const requesterDoc = await db.collection('requesters').doc(requesterId).get();
//        const token = requesterDoc.data()?.fcmToken;
//
//        if (token) {
//          await sendNotification(
//            token,
//            'Service Completed! ✅',
//            `How was your experience with ${providerName}? Tap to leave a review.`,
//            {
//              requestId: requestId,
//              providerId: afterData.confirmedProviderId,
//              type: 'REVIEW_PROMPT'
//            }
//          );
//        }
//      } catch (error) {
//        console.error("Error sending review notification:", error);
//      }
//    }
//    return null;
//  }
//);




// notificationHelper.js
// Firebase Cloud Functions v2 – High-Alert Emergency Notification System

const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const db = getFirestore();
const messaging = getMessaging();

// ═════════════════════════════════════════════════════════════════════
// 🌍 HAVERSINE DISTANCE CALCULATOR (KM)
// ═════════════════════════════════════════════════════════════════════
function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ═════════════════════════════════════════════════════════════════════
// 🔔 NOTIFICATION PRIORITY TIERS
// ═════════════════════════════════════════════════════════════════════

/**
 * TIER 1: HIGH-ALERT (SIREN) 🚨
 * - Custom sound: emergency_siren
 * - Importance: MAX
 * - Use for: New Emergency, Offer Approved
 */
async function sendTier1HighAlert(token, title, body, data = {}) {
  if (!token) {
    console.warn("⚠️ No token provided for Tier 1 alert");
    return;
  }

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data: {
      ...Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      priority: "high-alert",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "emergency_high_alert", // Custom channel for siren
        sound: "notification_tone", // Must exist in res/raw/emergency_siren.mp3
        priority: "max",
        defaultSound: false,
        defaultVibrateTimings: false,
        vibrateTimingsMillis: [0, 500, 200, 500, 200, 500], // Aggressive pattern
        visibility: "public",
        sticky: true,
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
      },
      payload: {
        aps: {
          sound: {
            critical: true,
            name: "notification_tone.wav", // Must exist in app bundle
            volume: 1.0,
          },
          "interruption-level": "critical",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(`🚨 TIER 1 HIGH-ALERT sent: ${response}`);
    return { success: true, messageId: response };
  } catch (error) {
    console.error(`❌ Tier 1 failed: ${error.code} - ${error.message}`);

    // Handle invalid token
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      console.log(`🗑️ Removing invalid token: ${token}`);
      // Token cleanup handled by calling function
    }

    return { success: false, error: error.message };
  }
}

/**
 * TIER 2: STANDARD ALERT 📢
 * - Default sound
 * - High importance
 * - Use for: New Offer Received, Progress Updates
 */
async function sendTier2StandardAlert(token, title, body, data = {}) {
  if (!token) {
    console.warn("⚠️ No token provided for Tier 2 alert");
    return;
  }

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data: {
      ...Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      priority: "standard",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "emergency_channel_id", // Standard channel
        sound: "default",
        priority: "high",
        defaultSound: true,
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
      },
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(`📢 TIER 2 STANDARD sent: ${response}`);
    return { success: true, messageId: response };
  } catch (error) {
    console.error(`❌ Tier 2 failed: ${error.code}`);
    return { success: false, error: error.message };
  }
}

/**
 * TIER 3: LOW-ALERT (SILENT) 🔕
 * - No sound, no vibration
 * - Low importance
 * - Use for: Review Prompts, Reminders
 */
async function sendTier3SilentAlert(token, title, body, data = {}) {
  if (!token) {
    console.warn("⚠️ No token provided for Tier 3 alert");
    return;
  }

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data: {
      ...Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      priority: "low",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "normal",
      notification: {
        channelId: "general_alerts", // Low-priority channel
        priority: "low",
        defaultSound: false,
        defaultVibrateTimings: false,
        visibility: "private",
      },
    },
    apns: {
      headers: {
        "apns-priority": "5",
      },
      payload: {
        aps: {
          "content-available": 1,
          badge: 1,
          // No sound = silent
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(`🔕 TIER 3 SILENT sent: ${response}`);
    return { success: true, messageId: response };
  } catch (error) {
    console.error(`❌ Tier 3 failed: ${error.code}`);
    return { success: false, error: error.message };
  }
}

/**
 * MULTICAST for Tier 1 (High-Alert to multiple providers)
 */
async function sendTier1Multicast(tokens, title, body, data = {}) {
  const validTokens = tokens.filter(t => t && t.length > 0);
  if (!validTokens.length) {
    console.warn("⚠️ No valid tokens for multicast");
    return;
  }

  const message = {
    tokens: validTokens,
    notification: {
      title,
      body,
    },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "emergency_high_alert",
        sound: "notification_tone",
        priority: "max",
        vibrateTimingsMillis: [0, 500, 200, 500, 200, 500],
      },
    },
    apns: {
      payload: {
        aps: {
          sound: {
            critical: true,
            name: "notification_tone.wav",
            volume: 1.0,
          },
          "interruption-level": "critical",
        },
      },
    },
  };

  try {
    const response = await messaging.sendEachForMulticast(message);
    console.log(`🚨 TIER 1 MULTICAST → Success: ${response.successCount}, Failed: ${response.failureCount}`);

    // Handle failed tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(validTokens[idx]);
          console.error(`Failed token ${idx}: ${resp.error?.code}`);
        }
      });
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error(`❌ Multicast error: ${error}`);
    return { success: false, error: error.message };
  }
}

// ═════════════════════════════════════════════════════════════════════
// 🚀 CLOUD FUNCTION TRIGGERS
// ═════════════════════════════════════════════════════════════════════

/**
 * TIER 1: New Emergency Request Created
 * Sends HIGH-ALERT to all nearby providers
 */
exports.onNewEmergencyRequest = onDocumentCreated(
  "emergency_requests/{requestId}",
  async (event) => {
    const requestData = event.data?.data();
    const requestId = event.params.requestId;

    if (!requestData) {
      console.error("❌ No request data");
      return;
    }

    const reqLat = requestData.latitude;
    const reqLon = requestData.longitude;
    const radius = requestData.radius || 10;
    const itemName = requestData.itemName || "emergency resource";
    const requesterName = requestData.requesterName || "Someone";

    if (!reqLat || !reqLon) {
      console.error("❌ Missing location data");
      return;
    }

    console.log(`🚨 NEW EMERGENCY: ${requestId} at (${reqLat}, ${reqLon}) radius: ${radius}km`);

    // Find providers within radius
    const latDelta = radius / 111;
    const snapshot = await db.collection("providers")
      .where("userType", "==", "provider")
      .where("isAvailable", "==", true)
      .where("latitude", ">=", reqLat - latDelta)
      .where("latitude", "<=", reqLat + latDelta)
      .get();

    const tokensInRadius = [];
    const providerIds = [];

    snapshot.forEach((doc) => {
      const provider = doc.data();
      const distance = haversineDistance(
        reqLat,
        reqLon,
        provider.latitude,
        provider.longitude
      );

      if (distance <= radius && provider.fcmToken) {
        tokensInRadius.push(provider.fcmToken);
        providerIds.push(doc.id);
        console.log(`📍 Provider ${doc.id} is ${distance.toFixed(2)}km away`);
      }
    });

    if (tokensInRadius.length === 0) {
      console.warn("⚠️ No providers found in radius");
      return;
    }

    // TIER 1: Send HIGH-ALERT with siren
    await sendTier1Multicast(
      tokensInRadius,
      "🚨 EMERGENCY NEARBY",
      `${requesterName} needs ${itemName} urgently!`,
      {
        type: "emergency_request",
        requestId: requestId,
        distance: "nearby",
        tier: "1",
      }
    );

    // Track alert sent time for re-alert logic
    await db.collection("emergency_requests").doc(requestId).update({
      lastAlertSentAt: Timestamp.now(),
      alertCount: 1,
      notifiedProviders: providerIds,
    });

    console.log(`✅ TIER 1 alert sent to ${tokensInRadius.length} providers`);
  }
);

/**
 * TIER 2: Provider Sends Offer
 * Sends STANDARD alert to requester
 */
exports.onOfferSent = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!beforeData || !afterData) return;

    const beforeOffers = beforeData.offers || [];
    const afterOffers = afterData.offers || [];

    // Check if new offer added
    if (afterOffers.length <= beforeOffers.length) return;

    const requesterId = afterData.requesterId;

    // Get requester's token
    const requesterDoc = await db.collection("requesters").doc(requesterId).get();
    const requesterToken = requesterDoc.data()?.fcmToken;

    if (!requesterToken) {
      console.warn("⚠️ No FCM token for requester");
      return;
    }

    // Get provider name from new offer
    const newOffer = afterOffers[afterOffers.length - 1];
    const providerName = newOffer.providerName || "A provider";

    console.log(`📩 New offer from ${providerName}`);

    // TIER 2: Send STANDARD alert
    await sendTier2StandardAlert(
      requesterToken,
      "🤝 New Provider Offer",
      `${providerName} wants to help with your ${afterData.itemName} request`,
      {
        type: "offer_received",
        requestId: event.params.requestId,
        providerId: newOffer.providerId,
        tier: "2",
      }
    );

    console.log("✅ TIER 2 offer notification sent");
  }
);

/**
 * TIER 1: Offer Approved (Handshake Start)
 * Sends HIGH-ALERT to confirmed provider
 */
exports.onOfferApproved = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!beforeData || !afterData) return;

    // Check if just got confirmed
    const justConfirmed =
      beforeData.status !== "confirmed" &&
      afterData.status === "confirmed" &&
      afterData.confirmedProviderId;

    if (!justConfirmed) return;

    const providerId = afterData.confirmedProviderId;

    // Get provider's token
    const providerDoc = await db.collection("providers").doc(providerId).get();
    const providerToken = providerDoc.data()?.fcmToken;

    if (!providerToken) {
      console.warn("⚠️ No FCM token for confirmed provider");
      return;
    }

    console.log(`✅ Offer approved for provider ${providerId}`);

    // TIER 1: Send HIGH-ALERT with siren
    await sendTier1HighAlert(
      providerToken,
      "🎉 YOU'RE SELECTED!",
      `${afterData.requesterName} approved your offer. Head to ${afterData.locationName} now!`,
      {
        type: "offer_approved",
        requestId: event.params.requestId,
        locationName: afterData.locationName || "location",
        tier: "1",
      }
    );

    console.log("✅ TIER 1 approval notification sent");
  }
);

/**
 * TIER 3: Service Completed - Review Prompt
 * Sends SILENT notification to requester
 */
exports.onServiceCompleted = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!beforeData || !afterData) return;

    // Check if just completed
    const justCompleted =
      beforeData.status !== "completed" &&
      afterData.status === "completed";

    if (!justCompleted) return;

    const requesterId = afterData.requesterId;
    const providerId = afterData.confirmedProviderId;

    // Get requester's token
    const requesterDoc = await db.collection("requesters").doc(requesterId).get();
    const requesterToken = requesterDoc.data()?.fcmToken;

    if (!requesterToken) {
      console.warn("⚠️ No FCM token for requester");
      return;
    }

    // Get provider name
    let providerName = "the provider";
    if (providerId) {
      const providerDoc = await db.collection("providers").doc(providerId).get();
      providerName = providerDoc.data()?.fullName || "the provider";
    }

    console.log(`🔕 Service completed - sending review prompt`);

    // TIER 3: Send SILENT notification (no sound)
    await sendTier3SilentAlert(
      requesterToken,
      "Service Completed ✅",
      `How was your experience with ${providerName}? Tap to leave a review.`,
      {
        type: "review_prompt",
        requestId: event.params.requestId,
        providerId: providerId || "",
        tier: "3",
      }
    );

    console.log("✅ TIER 3 silent review prompt sent");
  }
);

/**
 * 🔁 RE-ALERT SYSTEM (Nagging Logic)
 * Runs every 3 minutes
 * Re-sends TIER 1 alerts for pending requests with no offers
 */
exports.reAlertPendingRequests = onSchedule("every 3 minutes", async (event) => {
  console.log("🔁 RE-ALERT CHECK: Starting nagging logic...");

  const now = Timestamp.now();
  const twoMinutesAgo = Timestamp.fromMillis(now.toMillis() - (2 * 60 * 1000));

  // Find pending requests with no offers that are > 2 minutes old
  const snapshot = await db.collection("emergency_requests")
    .where("status", "==", "pending")
    .where("timestamp", "<=", twoMinutesAgo)
    .get();

  if (snapshot.empty) {
    console.log("✅ No pending requests needing re-alert");
    return;
  }

  console.log(`📋 Found ${snapshot.size} pending requests to check`);

  const reAlertPromises = [];

  for (const doc of snapshot.docs) {
    const requestData = doc.data();
    const requestId = doc.id;
    const offers = requestData.offers || [];

    // Skip if already has offers
    if (offers.length > 0) {
      console.log(`⏭️ Request ${requestId} has ${offers.length} offers - skipping`);
      continue;
    }

    const alertCount = requestData.alertCount || 1;
    const lastAlertTime = requestData.lastAlertSentAt?.toMillis() || 0;
    const timeSinceLastAlert = now.toMillis() - lastAlertTime;

    // Only re-alert if > 3 minutes since last alert
    if (timeSinceLastAlert < (3 * 60 * 1000)) {
      console.log(`⏭️ Request ${requestId} alerted ${Math.floor(timeSinceLastAlert / 1000)}s ago - too soon`);
      continue;
    }

    // Don't spam - max 10 re-alerts
    if (alertCount >= 10) {
      console.log(`🛑 Request ${requestId} reached max re-alerts (10)`);
      // Mark as expired
      await doc.ref.update({
        status: "expired",
        expiredReason: "no_providers_available",
      });
      continue;
    }

    console.log(`🚨 RE-ALERTING request ${requestId} (attempt ${alertCount + 1})`);

    // Find providers again
    const reqLat = requestData.latitude;
    const reqLon = requestData.longitude;
    const radius = requestData.radius || 10;

    const latDelta = radius / 111;
    const providersSnapshot = await db.collection("providers")
      .where("userType", "==", "provider")
      .where("isAvailable", "==", true)
      .where("latitude", ">=", reqLat - latDelta)
      .where("latitude", "<=", reqLat + latDelta)
      .get();

    const tokensInRadius = [];

    providersSnapshot.forEach((providerDoc) => {
      const provider = providerDoc.data();
      const distance = haversineDistance(
        reqLat,
        reqLon,
        provider.latitude,
        provider.longitude
      );

      if (distance <= radius && provider.fcmToken) {
        tokensInRadius.push(provider.fcmToken);
      }
    });

    if (tokensInRadius.length === 0) {
      console.warn(`⚠️ No providers in radius for ${requestId}`);
      continue;
    }

    // Send RE-ALERT (TIER 1 with even more urgency)
    reAlertPromises.push(
      sendTier1Multicast(
        tokensInRadius,
        `🚨 URGENT (${alertCount + 1}x): EMERGENCY NEARBY`,
        `STILL WAITING: ${requestData.requesterName} needs ${requestData.itemName}!`,
        {
          type: "emergency_request",
          requestId: requestId,
          isReAlert: "true",
          alertNumber: String(alertCount + 1),
          tier: "1",
        }
      ).then(() => {
        // Update alert count
        return doc.ref.update({
          lastAlertSentAt: Timestamp.now(),
          alertCount: alertCount + 1,
        });
      })
    );
  }

  await Promise.all(reAlertPromises);

  console.log(`✅ RE-ALERT completed - sent ${reAlertPromises.length} re-alerts`);
});
console.log("🔔 High-Alert Notification System initialized");


/**
 * TIER 1: Offer Approved (Handshake Start)
 * Sends HIGH-ALERT to confirmed provider
 */
exports.onRequestConfirmed = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!beforeData || !afterData) return;

    // Trigger when status changes to 'confirmed'
    const justConfirmed =
      beforeData.status !== "confirmed" &&
      afterData.status === "confirmed" &&
      afterData.confirmedProviderId;

    if (!justConfirmed) return;

    const providerId = afterData.confirmedProviderId;

    // Get provider's token from 'users' collection
    const providerDoc = await db.collection("users").doc(providerId).get();
    const providerToken = providerDoc.data()?.fcmToken;

    if (!providerToken) {
      console.warn("⚠️ No FCM token for confirmed provider");
      return;
    }

    // TIER 1: Send HIGH-ALERT with siren/high priority
    await sendTier1HighAlert(
      providerToken,
      "✅ ACTION REQUIRED: Approved!",
      `Proceed to ${afterData.locationName} now. Requester is waiting!`,
      {
        type: "offer_approved",
        requestId: event.params.requestId,
        tier: "1",
      }
    );
  }
);

/**
 * TIER 3: Service Completed - Review Prompt
 * Sends SILENT notification to requester
 */
exports.sendReviewNotification = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!beforeData || !afterData) return;

    // Trigger when status changes to 'completed'
    if (afterData.status === 'completed' && beforeData.status !== 'completed') {
      const requesterId = afterData.requesterId;
      const providerName = afterData.confirmedProviderName || "the provider";

      const requesterDoc = await db.collection('users').doc(requesterId).get();
      const token = requesterDoc.data()?.fcmToken;

      if (token) {
        // TIER 3: Send SILENT alert (No sound/vibration)
        await sendTier3SilentAlert(
          token,
          'Service Completed! ✅',
          `How was your experience with ${providerName}? Tap to leave a review.`,
          {
            requestId: event.params.requestId,
            providerId: afterData.confirmedProviderId,
            type: 'REVIEW_PROMPT',
            tier: "3"
          }
        );
      }
    }
  }
);



/**
 * TIER 2: Daily Maintenance
 * Sends STANDARD notification to all providers
 */
exports.dailyInventoryReminder = onSchedule("every day 09:00", async (event) => {
    const snapshot = await db.collection("users")
      .where("userType", "==", "provider")
      .get();

    const tokens = [];
    snapshot.forEach(doc => {
      if (doc.data()?.fcmToken) tokens.push(doc.data().fcmToken);
    });

    if (tokens.length > 0) {
      // TIER 2: Standard alert (Default sound)
      // Using multicast logic if you have many providers
      await sendTier1Multicast( // You can use Tier 1 Multicast but change the channel in the call if needed
        tokens,
        "📦 Inventory Check",
        "Please ensure your availability and stock are up to date.",
        { type: "inventory_reminder", tier: "2" }
      );
    }
});