import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reviews.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a review with duplicate prevention
  Future<void> submitReview(Review review) async {
    try {
      // 1. Check if already reviewed
      final existingReview = await _firestore
          .collection('reviews')
          .where('requestId', isEqualTo: review.requestId)
          .where('requesterId', isEqualTo: review.requesterId)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        throw Exception("You have already reviewed this request");
      }

      // 2. Write the review
      await _firestore.collection('reviews').add(review.toMap());

      // 3. Mark as reviewed in the request document
      await _firestore
          .collection('emergency_requests')
          .doc(review.requestId)
          .update({
        'isReviewed': true,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Review submitted successfully');
    } catch (e) {
      print('❌ Failed to submit review: $e');
      throw Exception("Failed to submit review: $e");
    }
  }

  /// Check if a request has been reviewed
  Future<bool> hasBeenReviewed(String requestId, String requesterId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('requestId', isEqualTo: requestId)
          .where('requesterId', isEqualTo: requesterId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking review status: $e');
      return false;
    }
  }
  /// Fetch provider's rating statistics and summary from the providers model
  Future<Map<String, dynamic>> getProviderStats(String providerId) async {
    try {
      final doc = await _firestore.collection('providers').doc(providerId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'avgRating': data['avgRating'] ?? 0.0,
          'reviewCount': data['reviewCount'] ?? 0,
          'summaryReview': data['summaryReview'] ?? "No summary available yet.",
        };
      } else {
        throw Exception("Provider not found");
      }
    } catch (e) {
      print('❌ Error fetching provider stats: $e');
      return {
        'avgRating': 0.0,
        'reviewCount': 0,
        'summaryReview': "Error loading summary.",
      };
    }
  }
  /// Get all reviews for a provider
  Future<List<Review>> getProviderReviews(String providerId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('providerId', isEqualTo: providerId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      return [];
    }
  }
}