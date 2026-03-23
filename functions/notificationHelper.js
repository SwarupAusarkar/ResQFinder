// notificationHelper.js
// Firebase Cloud Functions v2 – Production Safe Version

const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

const db = getFirestore();
const messaging = getMessaging();

// ─────────────────────────────────────────────
// 🌍 HAVERSINE DISTANCE (KM)
// ─────────────────────────────────────────────
function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ─────────────────────────────────────────────
// 🔔 SEND SINGLE NOTIFICATION (FIXED SYNTAX)
// ─────────────────────────────────────────────
async function sendNotification(token, title, body, data = {}) {
  if (!token) return;

  const message = {
    token,
    notification: { title, body },
    data: {
      ...Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "emergency_channel",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: { // Fixed: Now correctly inside the message object
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  };

  try {
    const res = await messaging.send(message);
    console.log("✅ FCM Sent:", res);
  } catch (err) {
    console.error("❌ FCM Error:", err.code);
  }
}

// ─────────────────────────────────────────────
// 🔔 SEND MULTICAST (Batch)
// ─────────────────────────────────────────────
async function sendMulticast(tokens, title, body, data = {}) {
  const validTokens = tokens.filter(t => t && t.length > 0);
  if (!validTokens.length) return;

  const message = {
    tokens: validTokens,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "emergency_channel",
        sound: "default",
      },
    },
  };

  try {
    const res = await messaging.sendEachForMulticast(message);
    console.log(`📢 Multicast → Success: ${res.successCount}, Fail: ${res.failureCount}`);
  } catch (err) {
    console.error("❌ Multicast Error:", err);
  }
}

// ─────────────────────────────────────────────
// 🚀 TRIGGERS
// ─────────────────────────────────────────────

exports.onNewEmergencyRequest = onDocumentCreated(
  "emergency_requests/{requestId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const reqLat = data.latitude ?? data.location?.latitude;
    const reqLon = data.longitude ?? data.location?.longitude;
    const radius = data.radius ?? 10;

    if (!reqLat || !reqLon) return;

    const latDelta = radius / 111;
    const snapshot = await db.collection("providers")
      .where("isAvailable", "==", true)
      .where("latitude", ">=", reqLat - latDelta)
      .where("latitude", "<=", reqLat + latDelta)
      .get();

    const tokensInRadius = [];
    snapshot.forEach((doc) => {
      const provider = doc.data();
      if (provider.fcmToken && haversineDistance(reqLat, reqLon, provider.latitude, provider.longitude) <= radius) {
        tokensInRadius.push(provider.fcmToken);
      }
    });

    await sendMulticast(tokensInRadius, "🚨 New Emergency Nearby", "Urgent help needed in your area.", { type: "new_request", requestId: event.params.requestId });
  }
);

exports.onOfferSent = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after || (after.offers?.length || 0) <= (before.offers?.length || 0)) return;

    const requesterDoc = await db.collection("requesters").doc(after.requesterId).get();
    const token = requesterDoc.data()?.fcmToken;

    await sendNotification(token, "📩 New Provider Offer", "A provider has offered to help.", { type: "offer_received", requestId: event.params.requestId });
  }
);

exports.onRequestConfirmed = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after || before.status === "confirmed" || after.status !== "confirmed") return;

    const providerDoc = await db.collection("providers").doc(after.confirmedProviderId).get();
    const token = providerDoc.data()?.fcmToken;

    await sendNotification(token, "✅ Offer Accepted!", "Proceed to the location.", { type: "offer_approved", requestId: event.params.requestId });
  }
);

exports.dailyInventoryReminder = onSchedule("every day 09:00", async () => {
    const snapshot = await db.collection("providers").get();
    const tokens = [];
    snapshot.forEach(doc => { if (doc.data()?.fcmToken) tokens.push(doc.data().fcmToken); });
    await sendMulticast(tokens, "📦 Daily Check", "Update your availability.", { type: "inventory_reminder" });
});

// FIXED: Removed redundant 'const { onDocumentUpdated } = ...' imports here
exports.sendReviewNotification = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const requestId = event.params.requestId;

    if (!beforeData || !afterData) return null;

    if (afterData.status === 'completed' && beforeData.status !== 'completed') {
      const requesterId = afterData.requesterId;
      const providerName = afterData.confirmedProviderName || "the provider";

      try {
        const requesterDoc = await db.collection('requesters').doc(requesterId).get();
        const token = requesterDoc.data()?.fcmToken;

        if (token) {
          await sendNotification(
            token,
            'Service Completed! ✅',
            `How was your experience with ${providerName}? Tap to leave a review.`,
            {
              requestId: requestId,
              providerId: afterData.confirmedProviderId,
              type: 'REVIEW_PROMPT'
            }
          );
        }
      } catch (error) {
        console.error("Error sending review notification:", error);
      }
    }
    return null;
  }
);