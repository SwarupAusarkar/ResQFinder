import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String? id;
  final String providerId;
  final String? providerName;
  final String requesterId;
  final String requestId;
  final String comment;
  final double rating;
  final DateTime? reviewDate;

  Review({
    this.id,
    required this.providerId,
    required this.providerName,
    required this.requesterId,
    required this.requestId,
    required this.comment,
    required this.rating,
    required this.reviewDate,
  });

  // --- NEW: fromMap Method ---
  factory Review.fromMap(Map<String, dynamic> data, {String? documentId}) {
    return Review(
      id: documentId,
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? 'Unknown Provider',
      requesterId: data['requesterId'] ?? '',
      requestId: data['requestId'] ?? '',
      comment: data['comment'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      // Handle potential Timestamp or String/DateTime conversions
      reviewDate: data['reviewDate'] is Timestamp
          ? (data['reviewDate'] as Timestamp).toDate()
          : (data['reviewDate'] != null ? DateTime.tryParse(data['reviewDate'].toString()) : null),
    );
  }

  // Updated fromFirestore to reuse the fromMap logic
  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Review.fromMap(data, documentId: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'providerName': providerName,
      'requesterId': requesterId,
      'requestId': requestId,
      'comment': comment,
      'rating': rating,
      'reviewDate': reviewDate ?? FieldValue.serverTimestamp(),
    };
  }
}