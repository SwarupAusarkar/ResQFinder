import 'package:flutter/material.dart';

import '../screens/auth_screen.dart' show AuthScreen;
import '../services/auth_service.dart' show AuthService;

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onProfileTap;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onProfileTap,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white, // Cozy White
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      )
          : Builder( // Burger Menu Trigger
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 28),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontFamily: 'Quicksand', // Cozy font choice
        ),
      ),
      actions: [
        // Notification Bell (Connected to your Tier 1/2 logic)
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
          onPressed: () {
            // Navigate to notification history
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black87),
          onPressed: () {
            _signOut(context);
          },
        ),
        // Profile Picture with tap action
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: onProfileTap,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orangeAccent, // Brand color
              backgroundImage: AssetImage('assets/images/user_avatar.png'),
              // Or use NetworkImage with Firebase profile URL
            ),
          ),
        ),
      ],
    );
  }
  Future<void> _signOut(BuildContext context) async {
    try {
      print("👋 Signing out from ServiceSelectionScreen...");
      await AuthService().signOut();

      if (context.mounted) {
        print("→ Navigating to home screen");
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
              (route) => false,
        );
      }
    } catch (e) {
      print("❌ Sign out error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}