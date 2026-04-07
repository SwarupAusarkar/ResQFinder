// import 'package:flutter/material.dart';
// import 'auth_screen.dart';
// // Home screen where users choose between Requester and Provider roles
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         // Gradient background for visual appeal
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF00897B), // Teal Green (theme color)
//               Color(0xFF4DB6AC), // Lighter teal accent
//                           ],
//           ),
//         ),
//
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // App logo and title
//                 const Icon(
//                   Icons.local_hospital,
//                   size: 80,
//                   color: Colors.white,
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Emergency Resource\nLocator',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     height: 1.2,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Find help when you need it most',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.white70,
//                   ),
//                 ),
//                 const SizedBox(height: 60),
//
//                 // User type selection cards
//                 const Text(
//                   'Who are you?',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//
//                 // Requester card
//                 _buildUserTypeCard(
//                   context: context,
//                   title: 'I Need Help',
//                   subtitle: 'Find emergency services near me',
//                   icon: Icons.search,
//                   userType: 'requester',
//                   color: Colors.white,
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Provider card
//                 _buildUserTypeCard(
//                   context: context,
//                   title: 'I Provide Service',
//                   subtitle: 'Respond to emergency requests',
//                   icon: Icons.medical_services,
//                   userType: 'provider',
//                   color: Colors.white,
//                 ),
//
//                 const Spacer(),
//
//                 // Footer text
//                 const Text(
//                   'Emergency services available 24/7',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.white60,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Build user type selection card
//   Widget _buildUserTypeCard({
//     required BuildContext context,
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required String userType,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: InkWell(
//           onTap: () {
//             if (userType == 'provider') {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const AuthScreen(),
//                   settings: RouteSettings(arguments: {'userType': 'provider'}),
//                 ),
//               );
//             } else if (userType == 'requester') {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const AuthScreen(),
//                   settings: RouteSettings(arguments: {'userType': 'requester'}),
//                 ),
//               );
//             }
//           },
//
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: userType == 'requester'
//                       ? Colors.blue.withOpacity(0.1)
//                       : Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 32,
//                   color: userType == 'requester' ? Colors.blue : Colors.green,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.arrow_forward_ios,
//                 color: Colors.grey[400],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── Logic (unchanged) ────────────────────────────────────────────────────────
  void _navigate(BuildContext context, String userType) {
    if (userType == 'admin') {
      // Admin uses email login only – no phone
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthScreen(),
          settings: const RouteSettings(arguments: {'userType': 'admin'}),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
        settings: RouteSettings(arguments: {'userType': userType}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D4F4A), Color(0xFF0D9488)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _LogoSection(),
              const Spacer(flex: 2),
              _RoleCardsSection(onNavigate: _navigate),
              const Spacer(flex: 1),
              _FooterNote(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.medical_services_rounded, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'EMERGEO',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your emergency gateway...',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _RoleCardsSection extends StatelessWidget {
  final void Function(BuildContext, String) onNavigate;
  const _RoleCardsSection({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Requester + Provider side-by-side
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  icon: Icons.search_rounded,
                  title: 'I Need Help',
                  subtitle: 'Find emergency services near me',
                  actionLabel: 'GO',
                  cardColor: Colors.white,
                  iconBg: const Color(0xFFEFF6F5),
                  iconColor: const Color(0xFF0D9488),
                  actionColor: const Color(0xFF0D9488),
                  onTap: () => onNavigate(context, 'requester'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _RoleCard(
                  icon: Icons.medical_services_rounded,
                  title: 'I Provide Service',
                  subtitle: 'Respond to emergency requests',
                  actionLabel: 'JOIN',
                  cardColor: Colors.white,
                  iconBg: const Color(0xFFEFF6F5),
                  iconColor: const Color(0xFF0D9488),
                  actionColor: const Color(0xFF6D28D9),
                  onTap: () => onNavigate(context, 'provider'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Admin full-width card (subtle, smaller)
          _AdminCard(onTap: () => onNavigate(context, 'admin')),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color cardColor;
  final Color iconBg;
  final Color iconColor;
  final Color actionColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.cardColor,
    required this.iconBg,
    required this.iconColor,
    required this.actionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0D4F4A)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            // Action button pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AdminCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Portal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('System management & oversight', style: TextStyle(fontSize: 11, color: Colors.white60)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'EMERGENCY SERVICES AVAILABLE 24/7',
      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), letterSpacing: 1.5, fontWeight: FontWeight.w600),
    );
  }
}