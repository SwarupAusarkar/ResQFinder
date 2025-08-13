import 'package:flutter/material.dart';
import '../models/provider_model.dart';

class ProviderDetailsScreen extends StatelessWidget {
  final Provider provider;

  const ProviderDetailsScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(provider.address, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "Distance: ${provider.distance.toStringAsFixed(1)} km",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              provider.isAvailable ? "Available ✅" : "Not Available ❌",
              style: TextStyle(
                fontSize: 16,
                color: provider.isAvailable ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text("Call Provider"),
              onPressed: () {
                // TODO: implement phone call feature
              },
            ),
          ],
        ),
      ),
    );
  }
}