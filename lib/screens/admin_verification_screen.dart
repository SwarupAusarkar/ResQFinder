// lib/screens/admin_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminVerificationScreen extends StatelessWidget {
  final String providerId;
  final Map<String, dynamic> providerData;

  const AdminVerificationScreen({super.key, required this.providerId, required this.providerData});

  // Makes the database update
  Future<void> _updateStatus(BuildContext context, String status, bool isAvailable) async {
    try {
      await FirebaseFirestore.instance.collection('providers').doc(providerId).update({
        'verificationStatus': status,
        'isAvailable': isAvailable, // This unlocks them in the app!
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Provider officially $status!'), 
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Uses url_launcher to safely open PDFs or Images in the native browser
  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final certUrl = providerData['certificateUrl'] ?? '';
    final List<dynamic> facilityUrls = providerData['facilityUrls'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(providerData['name'] ?? 'Verification'), backgroundColor: Colors.black87, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Provider Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text("Phone: ${providerData['phone']}"),
            Text("Address: ${providerData['address']}"),
            Text("Type: ${providerData['providerType']}"),
            const SizedBox(height: 24),
            
            const Text("Official Certificate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            if (certUrl.toString().isEmpty)
              const Text("No certificate uploaded. (Do not approve)", style: TextStyle(color: Colors.red))
            else
              ElevatedButton.icon(
                onPressed: () => _launchURL(certUrl, context),
                icon: const Icon(Icons.open_in_new),
                label: const Text("View Certificate Document"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            
            const SizedBox(height: 24),
            const Text("Facility Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            if (facilityUrls.isEmpty)
              const Text("No photos uploaded.", style: TextStyle(color: Colors.red))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: facilityUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _launchURL(facilityUrls[index], context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(facilityUrls[index], fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
            
            // ADMIN CONTROLS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(context, 'rejected', false),
                    icon: const Icon(Icons.close),
                    label: const Text("REJECT"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red, width: 2), padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(context, 'approved', true),
                    icon: const Icon(Icons.check),
                    label: const Text("APPROVE"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}