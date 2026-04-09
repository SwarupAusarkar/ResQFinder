// lib/constants.dart
import 'package:flutter/material.dart';

// Color palette
const primaryColor = Color(0xFF00897B); // Teal (matching your app theme)
const secondaryColor = Color(0xFFFF8A80); // Soft Coral (accent)
const inactiveColor = Color(0xFF9E9E9E);
const backgroundColor = Color(0xFFF8F9FA);

// ═══════════════════════════════════════════════════════════════
// PROVIDER NAVIGATION TABS
// ═══════════════════════════════════════════════════════════════
final List<Map<String, dynamic>> providerTabs = [
  {
    'name': 'Dashboard',
    'icon': Icons.notifications_active_outlined,
    'path': '/provider-dashboard',
    'index': 0,
  },
  {
    'name': 'History',
    'icon': Icons.history,
    'path': '/provider-history',
    'index': 2,
  },
  {
    'name': 'Profile',
    'icon': Icons.person_outline,
    'path': '/provider-profile',
    'index': 3,
  },
];

// ═══════════════════════════════════════════════════════════════
// REQUESTER NAVIGATION TABS
// ═══════════════════════════════════════════════════════════════
final List<Map<String, dynamic>> requesterTabs = [
  {
    'name': 'Home',
    'icon': Icons.home_outlined,
    'path': '/requester-home',
    'index': 0,
  },
  {
    'name': 'Requests',
    'icon': Icons.list_alt_rounded,
    'path': '/requester-dashboard',
    'index': 1,
  },
  {
    'name': 'History',
    'icon': Icons.history_outlined,
    'path': '/requester-history',
    'index': 2,
  },
  {
    'name': 'Profile',
    'icon': Icons.person_outline,
    'path': '/requester-profile',
    'index': 3,
  },
  {
    'name': 'Settings',
    'icon': Icons.settings_outlined,
    'path': '/requester-settings',
    'index': 4,
  },
];

// ═══════════════════════════════════════════════════════════════
// COMMON ROUTES (accessible from anywhere)
// ═══════════════════════════════════════════════════════════════
class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String signup = '/signup';
  // static const String splash = '/splash';

  // Provider Routes
  static const String providerMain = '/provider-main';
  static const String providerDashboard = '/provider-dashboard';
  static const String manageInventory = '/manage-inventory';
  static const String providerHistory = '/provider-history';
  static const String providerProfile = '/provider-profile';

  // Requester Routes
  static const String requesterMain = '/requester-main';
  static const String requesterHome = '/provider-list';
  static const String requesterHistory = '/requester-history';
  static const String requesterProfile = '/requester-profile';
  static const String requesterSettings = '/requester-settings';

  // Shared
  static const String sendRequest = '/send-request';
  static const String offerApproval = '/offer-approval';
  static const String trackProvider = '/track-provider';
  static const String notifications = '/notifications';
}