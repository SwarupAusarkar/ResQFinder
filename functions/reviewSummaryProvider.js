const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore"); // Use FieldValue from here
const { GoogleGenerativeAI } = require("@google/generative-ai");

const db = getFirestore();
// Ensure you have the API key in your environment variables
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

exports.onReviewCreated = onDocumentCreated(
  "reviews/{reviewId}", // Ensure this matches your collection name exactly
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const reviewData = snap.data();
    const providerId = reviewData.providerId;
    const requestId = reviewData.requestId;

    if (!providerId) {
      console.error("❌ No providerId in review document");
      return;
    }

    // Reference the 'users' collection (or 'providers' if that's where stats live)
    // Based on your previous code, check if it's 'users' or 'providers'
    const userRef = db.collection("providers").doc(providerId);

    try {
          const userDoc = await userRef.get();
          const userData = userDoc.data() || {};

          // Pull existing data or set defaults
          const oldCount = userData.reviewCount || 0;
          const oldAvg = userData.avgRating || 0;
          const oldSummary = userData.summarizedReview || ""; // Changed to empty string for logic check

          const newRating = reviewData.rating || 0;
          const newComment = reviewData.comment || "No comment provided";

          // 2. Calculate new average
          const newCount = oldCount + 1;
          const newAvg = ((oldAvg * oldCount) + newRating) / newCount;

          // 3. AI Summary Logic
          let aiSummary = oldSummary || newComment; // Default fallback to current comment if no old summary exists

          try {
            const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-lite" });

            // Refined Prompt for better consistency
            const prompt = `Act as a professional profile editor.
            Current Summary: "${oldSummary || "No previous reviews."}"
            New Review: "${newComment}"
            Action: Update the summary into ONE concise, professional sentence (max 15 words) reflecting the provider's reputation.
            Constraint: Return ONLY the plain text summary. No quotes, no intro text.`;

            const result = await model.generateContent(prompt);
            const responseText = result.response.text().trim();

            if (responseText && responseText.length > 2) {
              // Remove any accidental markdown or quotes from the AI
              aiSummary = responseText.replace(/^["']|["']$/g, '').replace(/[\r\n]+/gm, " ");
            }
          } catch (aiError) {
            console.error("⚠️ Gemini Error - Falling back to latest comment:", aiError.message);
            // Fallback: If AI fails, we just use the latest comment so it's not "New Provider" anymore
            aiSummary = newComment.length > 50 ? newComment.substring(0, 47) + "..." : newComment;
          }

          // 4. Update Document
          await userRef.update({
            avgRating: parseFloat(newAvg.toFixed(1)),
            reviewCount: newCount,
            summarizedReview: aiSummary, // This will now definitely be different than "New provider"
            lastReviewedAt: FieldValue.serverTimestamp(),
          });

      console.log(`✅ Stats updated for provider: ${providerId}`);
    } catch (error) {
      console.error("❌ Error in onReviewCreated:", error);
    }
  }
);