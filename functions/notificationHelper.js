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




// Firebase Cloud Functions v2 – High-Alert Emergency Notification System
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const db = getFirestore();
const messaging = getMessaging();

// 💡 Define the region once to keep code clean
const REGION = "asia-south1";

// ═════════════════════════════════════════════════════════════════════
// 🌍 HAVERSINE DISTANCE CALCULATOR (KM)
// ═════════════════════════════════════════════════════════════════════
function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
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

async function sendTier1HighAlert(token, title, body, data = {}) {
  if (!token) return;
  const message = {
    token,
    notification: { title, body },
    data: { ...data, priority: "high-alert" },
    android: {
      priority: "high",
      notification: {
        channelId: "emergency_high_alert",
        sound: "notification_tone",
        priority: "max",
      },
    },
    apns: {
      payload: { aps: { sound: { critical: true, name: "notification_tone.wav", volume: 1.0 } } },
    },
  };
  return messaging.send(message);
}

async function sendTier2StandardAlert(token, title, body, data = {}) {
  if (!token) return;
  const message = {
    token,
    notification: { title, body },
    data: { ...data, priority: "standard" },
    android: { notification: { channelId: "emergency_channel_id", sound: "default" } },
  };
  return messaging.send(message);
}

async function sendTier3SilentAlert(token, title, body, data = {}) {
  if (!token) return;
  const message = {
    token,
    notification: { title, body },
    data: { ...data, priority: "low" },
    android: { notification: { channelId: "general_alerts", priority: "low", defaultSound: false } },
  };
  return messaging.send(message);
}

async function sendTier1Multicast(tokens, title, body, data = {}) {
  const validTokens = tokens.filter(t => t && t.length > 0);
  if (!validTokens.length) return;

  const message = {
    tokens: validTokens,
    notification: { title, body },
    // 🚨 Sabhi values ko String mein convert karein
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "emergency_high_alert", // Yeh ID Flutter mein honi chahiye
        sound: "notification_tone",
        priority: "max",
      },
    },
  };
  return messaging.sendEachForMulticast(message);
}

// ═════════════════════════════════════════════════════════════════════
// 🚀 CLOUD FUNCTION TRIGGERS (Region: asia-south1)
// ═════════════════════════════════════════════════════════════════════

/**
 * TRIGGER 1: New Request Created
 */
exports.onNewEmergencyRequest = onDocumentCreated(
  { document: "emergency_requests/{requestId}", region: REGION },
  async (event) => {
    const requestData = event.data?.data();
    if (!requestData) return;

    const reqLat = requestData.latitude;
    const reqLon = requestData.longitude;
    const radius = requestData.radius || 10;

    const snapshot = await db.collection("providers").where("isAvailable", "==", true).get();

    const tokensInRadius = [];
    const providerIds = [];

    snapshot.forEach((doc) => {
      const provider = doc.data();
      const dist = haversineDistance(reqLat, reqLon, provider.latitude, provider.longitude);
      if (dist <= radius && provider.fcmToken) {
        tokensInRadius.push(provider.fcmToken);
        providerIds.push(doc.id);
      }
    });

    if (tokensInRadius.length > 0) {
      await sendTier1Multicast(
        tokensInRadius,
        "🚨 EMERGENCY NEARBY",
        `${requestData.requesterName} needs ${requestData.itemName}!`,
        { type: "emergency_request", requestId: event.params.requestId }
      );

      await event.data.ref.update({
        lastAlertSentAt: Timestamp.now(),
        alertCount: 1,
        notifiedProviders: providerIds,
      });
    }
  }
);

/**
 * TRIGGER 2: Provider sends offer
 */
exports.onOfferSent = onDocumentUpdated(
  { document: "emergency_requests/{requestId}", region: REGION },
  async (event) => {
    const beforeOffers = event.data?.before?.data()?.offers || [];
    const afterOffers = event.data?.after?.data()?.offers || [];

    if (afterOffers.length > beforeOffers.length) {
      const data = event.data.after.data();
      const reqDoc = await db.collection("requesters").doc(data.requesterId).get();
      const token = reqDoc.data()?.fcmToken;

      if (token) {
        await sendTier2StandardAlert(
          token,
          "🤝 New Offer Received",
          "A provider has responded to your request.",
          { type: "offer_received", requestId: event.params.requestId }
        );
      }
    }
  }
);

/**
 * TRIGGER 3: Request Confirmed
 */
exports.onRequestConfirmed = onDocumentUpdated(
  { document: "emergency_requests/{requestId}", region: REGION },
  async (event) => {
    const after = event.data.after.data();
    const before = event.data.before.data();

    if (after.status === "confirmed" && before.status !== "confirmed") {
      const provDoc = await db.collection("providers").doc(after.confirmedProviderId).get();
      const token = provDoc.data()?.fcmToken;

      if (token) {
        await sendTier1HighAlert(
          token,
          "✅ YOU ARE SELECTED!",
          `Go to ${after.locationName} now. Requester is waiting.`,
          { type: "offer_approved", requestId: event.params.requestId }
        );
      }
    }
  }
);

/**
 * TRIGGER 4: Request Completed
 */
exports.sendReviewNotification = onDocumentUpdated(
  { document: "emergency_requests/{requestId}", region: REGION },
  async (event) => {
    const after = event.data.after.data();
    const before = event.data.before.data();

    if (after.status === "completed" && before.status !== "completed") {
      const reqDoc = await db.collection("requesters").doc(after.requesterId).get();
      const token = reqDoc.data()?.fcmToken;

      if (token) {
        await sendTier3SilentAlert(
          token,
          "Service Completed ✅",
          "Please take a moment to review the provider.",
          { type: "review_prompt", requestId: event.params.requestId }
        );
      }
    }
  }
);

/**
 * TRIGGER 5: Nagging Logic
 */
exports.reAlertPendingRequests = onSchedule(
  { schedule: "every 3 minutes", region: REGION },
  async (event) => {
    const now = Timestamp.now();
    const threshold = Timestamp.fromMillis(now.toMillis() - (2 * 60 * 1000));

    const pending = await db.collection("emergency_requests")
      .where("status", "==", "pending")
      .where("timestamp", "<=", threshold)
      .get();

    for (const doc of pending.docs) {
      const data = doc.data();
      if ((data.offers || []).length === 0) {
        const providers = await db.collection("providers").where("isAvailable", "==", true).get();
        const tokens = providers.docs.map(p => p.data().fcmToken).filter(t => t);

        if (tokens.length > 0) {
          await sendTier1Multicast(tokens, "🚨 STILL WAITING", `No response for ${data.itemName} yet!`, { tier: "1" });
        }
      }
    }
  }
);

/**
 * TRIGGER 6: Daily Inventory Reminder
 */
exports.dailyInventoryReminder = onSchedule(
  { schedule: "every day 09:00", region: REGION },
  async (event) => {
    const snapshot = await db.collection("providers").get();
    const tokens = snapshot.docs.map(doc => doc.data().fcmToken).filter(t => t);

    if (tokens.length > 0) {
      await sendTier2StandardAlert(tokens, "📦 Inventory Check", "Keep your stock status updated.", { type: "reminder" });
    }
});