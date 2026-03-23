import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/ReviewService.dart';
import '../models/reviews.dart';

class ReviewDialog extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String requesterId;
  final String requestId;

  const ReviewDialog({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.requesterId,
    required this.requestId,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double _currentRating = 3.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFF00897B), size: 50),
          const SizedBox(height: 10),
          Text(
            "Rate ${widget.providerName}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "How was the service provided?",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // STAR RATING: 0.5 Increments
            RatingBar.builder(
              initialRating: 3,
              minRating: 0.5,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder:
                  (context, _) =>
                      const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() => _currentRating = rating);
              },
            ),
            const SizedBox(height: 10),
            Text(
              "$_currentRating / 5.0",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.amber,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Tell us more about your experience...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Maybe Later",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmission,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    "Submit Review",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ],
    );
  }

  Future<void> _handleSubmission() async {
    setState(() => _isSubmitting = true);

    final review = Review(
      providerId: widget.providerId,
      providerName: widget.providerName,
      requesterId: widget.requesterId,
      requestId: widget.requestId,
      comment: _commentController.text.trim(),
      rating: _currentRating,
      reviewDate: DateTime.now(),
    );

    try {
      await ReviewService().submitReview(review);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thank you for your feedback!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
