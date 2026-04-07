// lib/screens/service_selection_screen.dart
import 'package:emergency_res_loc_new/screens/request_history_screen.dart';
import 'package:emergency_res_loc_new/screens/requester_profile_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  // ── Logic (unchanged) ────────────────────────────────────────────────────────
  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Emergency Call')]),
        content: const Text(
          'This is a demo app. In a real emergency, you would be connected to 112 emergency services.\n\n'
              'Indian Emergency Numbers:\n• 112 - All Emergency Services\n• 100 - Police\n• 101 - Fire Department\n• 108 - Ambulance',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Understood'))],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6F5),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onSignOut: () => _signOut(context),
              onProfile: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequesterProfileScreen())),
              onHistory: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequesterHistoryScreen())),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _Header(),
                    const SizedBox(height: 28),
                    _ServiceCard(
                      title: 'Hospital & ER',
                      subtitle: 'Emergency rooms • Doctors • ICU',
                      icon: '🏥',
                      serviceType: 'hospital',
                      badgeText: 'NEAREST: 1.2KM',
                      badgeColor: const Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 14),
                    _ServiceCard(
                      title: 'Police',
                      subtitle: 'Immediate local protection',
                      icon: '🛡️',
                      serviceType: 'police',
                      badgeText: null,
                      badgeColor: Colors.blue,
                    ),
                    const SizedBox(height: 14),
                    _ServiceCard(
                      title: 'Ambulance',
                      subtitle: 'BLS, ALS & Neonatal',
                      icon: '🚑',
                      serviceType: 'ambulance',
                      badgeText: null,
                      badgeColor: Colors.orange,
                    ),
                    const SizedBox(height: 32),
                    _QuickDialSection(onEmergencyTap: () => _showEmergencyDialog(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onSignOut;
  final VoidCallback onProfile;
  final VoidCallback onHistory;

  const _TopBar({required this.onSignOut, required this.onProfile, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(
        children: [
          const Spacer(),
          _IconBtn(icon: Icons.history_rounded, onTap: onHistory),
          const SizedBox(width: 6),
          _IconBtn(icon: Icons.person_rounded, onTap: onProfile),
          const SizedBox(width: 6),
          _IconBtn(icon: Icons.logout_rounded, onTap: onSignOut),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0D4F4A)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What type of\nemergency service\ndo you need?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D4F4A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Swift response within 10–15 minutes in your area.',
          style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.4),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final String serviceType;
  final String? badgeText;
  final Color badgeColor;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.serviceType,
    required this.badgeText,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/provider-list', arguments: {'serviceType': serviceType}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Icon box
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
                  ),
                  if (badgeText != null)
                    Positioned(
                      top: -10,
                      right: -40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0D4F4A))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickDialSection extends StatelessWidget {
  final VoidCallback onEmergencyTap;
  const _QuickDialSection({required this.onEmergencyTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'QUICK DIAL INDIA SERVICES'),
        const SizedBox(height: 12),
        Row(
          children: [
            _DialButton(number: '112', label: 'ALL HELP', color: const Color(0xFFDC2626), onTap: onEmergencyTap),
            const SizedBox(width: 10),
            _DialButton(number: '102', label: 'MEDICAL', color: const Color(0xFF0D9488), onTap: onEmergencyTap),
            const SizedBox(width: 10),
            _DialButton(number: '100', label: 'POLICE', color: const Color(0xFF1D4ED8), onTap: onEmergencyTap),
          ],
        ),
      ],
    );
  }
}

class _DialButton extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialButton({required this.number, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Text(number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5),
    );
  }
}