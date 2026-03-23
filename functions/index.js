const { setGlobalOptions } = require("firebase-functions/v2/firestore");
const functions = require("firebase-functions/v2/firestore"); // Legacy support for Firestore triggers
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// Initialization
initializeApp();
const db = getFirestore();

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);


const n = require("./notificationHelper");
exports.onNewEmergencyRequest = n.onNewEmergencyRequest;
exports.onOfferSent = n.onOfferSent;
exports.onRequestConfirmed = n.onRequestConfirmed;
exports.dailyInventoryReminder = n.dailyInventoryReminder;
exports.sendReviewNotification=n.sendReviewNotification;
const r=require("./reviewSummaryProvider");
exports.onReviewCreated=r.onReviewCreated;
