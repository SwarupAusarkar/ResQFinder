import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class NavigationService {
  static Future<void> openMap(
      double latitude, double longitude, String name, BuildContext context) async {
    
    // We use the official Google Maps 'dir' (directions) API URL.
    // This forces the app to route exactly to these coordinates, ignoring name ambiguities.
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    final Uri uri = Uri.parse(googleMapsUrl);

    try {
      if (await canLaunchUrl(uri)) {
        // LaunchMode.externalApplication ensures it escapes the Flutter app 
        // and forces the native Google Maps app to open if it is installed.
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError(context);
      }
    } catch (e) {
      _showError(context);
    }
  }

  static void _showError(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open map application.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}