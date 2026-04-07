import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RatingSummaryCard extends StatelessWidget {
  final double avgRating;
  final int reviewCount;
  final String summaryReview;

  const RatingSummaryCard({super.key, required this.avgRating, required this.reviewCount, required this.summaryReview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0D4F4A))),
                  Text("$reviewCount Patient Reviews", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              Row(
                children: List.generate(5, (index) => Icon(Icons.star_rounded, color: index < avgRating.floor() ? Colors.orange : Colors.grey[200], size: 24)),
              )
            ],
          ),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
            child: Text("\"$summaryReview\"", style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF065F46), fontSize: 13, height: 1.5)),
          )
        ],
      ),
    );
  }
}