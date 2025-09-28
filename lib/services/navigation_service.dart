import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class NavigationService {
  static Future<void> openMap(
      double latitude, double longitude, String name, BuildContext context) async {
    final uri = Uri.tryParse('geo:$latitude,$longitude?q=${Uri.encodeComponent(name)}');

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback for web or if no map app is available
      final webUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open map application.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}