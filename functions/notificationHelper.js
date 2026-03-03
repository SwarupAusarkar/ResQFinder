// notificationHelper.js
// Firebase Cloud Functions v2 – Production Safe Version

const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const db = getFirestore();
const messaging = getMessaging();


// ─────────────────────────────────────────────
// 🌍 HAVERSINE DISTANCE (KM)
// ─────────────────────────────────────────────
function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in KM
  const toRad = (deg) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) ** 2;

  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}


// ─────────────────────────────────────────────
// 🔔 SEND SINGLE NOTIFICATION
// ─────────────────────────────────────────────
async function sendNotification(token, title, body, data = {}) {
  if (!token) return;

  const message = {
    token,
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
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
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
  if (!tokens.length) return;

  const message = {
    tokens,
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
    console.log(
      `📢 Multicast → Success: ${res.successCount}, Fail: ${res.failureCount}`
    );
  } catch (err) {
    console.error("❌ Multicast Error:", err);
  }
}



// ─────────────────────────────────────────────
// 1️⃣ NEW EMERGENCY REQUEST
// Notify Nearby Providers
// ─────────────────────────────────────────────
exports.onNewEmergencyRequest = onDocumentCreated(
  "emergency_requests/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;
    const data = event.data?.data();

    if (!data) return;

    console.log("🚨 New Request Triggered:", requestId);

    const reqLat = data.latitude ?? data.location?.latitude;
    const reqLon = data.longitude ?? data.location?.longitude;
    const radius = data.radius ?? 10;

    if (!reqLat || !reqLon) {
      console.log("❌ Missing coordinates");
      return;
    }

    // 🌍 Convert KM → Degree Bounding Box
    const latDelta = radius / 111;
    const lonDelta =
      radius / (111 * Math.cos((reqLat * Math.PI) / 180));

    const minLat = reqLat - latDelta;
    const maxLat = reqLat + latDelta;
    const minLon = reqLon - lonDelta;
    const maxLon = reqLon + lonDelta;

    // 🔎 Firestore Bounding Query
    const snapshot = await db
      .collection("providers")
      .where("isAvailable", "==", true)
      .where("latitude", ">=", minLat)
      .where("latitude", "<=", maxLat)
      .get();

    const tokensInRadius = [];

    snapshot.forEach((doc) => {
      const provider = doc.data();

      if (!provider.fcmToken) return;

      const provLat = provider.latitude;
      const provLon = provider.longitude;

      if (
        provLon >= minLon &&
        provLon <= maxLon
      ) {
        const distance = haversineDistance(
          reqLat,
          reqLon,
          provLat,
          provLon
        );

        if (distance <= radius) {
          tokensInRadius.push(provider.fcmToken);
        }
      }
    });

    console.log("📍 Providers in Radius:", tokensInRadius.length);

    const citizenName = data.requesterName || "A nearby citizen";
    const emergencyType = data.emergencyType || "Emergency Assistance";
    const address = data.address || "your area";

    await sendMulticast(
      tokensInRadius,
      "🚨 New Emergency Nearby",
      `${citizenName} needs ${emergencyType} near ${address}. Check and respond quickly.`,
      {
        type: "new_request",
        requestId,
        emergencyType,
        address
      }
    );
  }
);



// ─────────────────────────────────────────────
// 2️⃣ PROVIDER SENT OFFER
// Notify Requester
// ─────────────────────────────────────────────
exports.onOfferSent = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;

    const prevOffers = before.offers?.length ?? 0;
    const newOffers = after.offers?.length ?? 0;

    if (newOffers <= prevOffers) return;

    console.log("📩 New Offer Triggered:", requestId);

    const requesterId = after.requesterId;
    if (!requesterId) return;

    const requesterDoc = await db
      .collection("requesters")
      .doc(requesterId)
      .get();

    const token = requesterDoc.data()?.fcmToken;
    if (!token) return;

    const latestOffer = after.offers?.[after.offers.length - 1];
    const providerName = latestOffer?.providerName || "A provider";

    await sendNotification(
      token,
      "📩 New Provider Offer",
      `${providerName} has offered to help you. Review and confirm if suitable.`,
      {
        type: "offer_received",
        requestId,
        providerName
      }
    );
  }
);


// ─────────────────────────────────────────────
// 3️⃣ REQUEST CONFIRMED
// Notify Selected Provider
// ─────────────────────────────────────────────
exports.onRequestConfirmed = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;

    if (before.status === "confirmed") return;
    if (after.status !== "confirmed") return;

    console.log("✅ Request Confirmed:", requestId);

    const providerId = after.confirmedProviderId;
    if (!providerId) return;

    const providerDoc = await db
      .collection("providers")
      .doc(providerId)
      .get();

    const token = providerDoc.data()?.fcmToken;
    if (!token) return;

    const citizenName = after.requesterName || "The citizen";
    const address = after.address || "their location";

    await sendNotification(
      token,
      "✅ Offer Accepted!",
      `${citizenName} has approved your offer. Proceed to ${address} and complete the request.`,
      {
        type: "offer_approved",
        requestId,
        address
      }
    );
  }
);



// ─────────────────────────────────────────────
// 4️⃣ DAILY INVENTORY REMINDER
// (Blaze Plan Required)
// ─────────────────────────────────────────────
exports.dailyInventoryReminder = onSchedule(
  "every day 09:00",
  async () => {
    console.log("📦 Running Daily Reminder");

    const snapshot = await db.collection("providers").get();

    const tokens = [];

    snapshot.forEach((doc) => {
      const token = doc.data()?.fcmToken;
      if (token) tokens.push(token);
    });

    await sendMulticast(
      tokens,
      "📦 Daily Inventory Check",
      "Please update your availability and stock status to receive relevant emergency requests today.",
      { type: "inventory_reminder" }
    );
  }
);