// lib/screens/searching_providers_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shown immediately after the SOS request is broadcast.
/// Matches ss4: light mint background, animated logo, "Searching for nearby providers..." text.
/// Auto-navigates back after a brief delay or user can dismiss.
class SearchingProvidersScreen extends StatefulWidget {
  const SearchingProvidersScreen({super.key});

  @override
  State<SearchingProvidersScreen> createState() =>
      _SearchingProvidersScreenState();
}

class _SearchingProvidersScreenState extends State<SearchingProvidersScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ────────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final AnimationController _dotController;
  late final AnimationController _orbitController;

  late final Animation<double> _pulseAnim;
  late final Animation<double> _dotAnim;
  late final Animation<double> _orbitAnim;

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const _teal = Color(0xFF0D9488);
  static const _tealDark = Color(0xFF0D4F4A);
  static const _bgColor = Color(0xFFEBF7F6); // matches ss4 mint bg

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _dotAnim = Tween<double>(begin: 0, end: 1).animate(_dotController);
    _orbitAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _orbitController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Scattered small decorative dots matching ss4
            ..._buildDecorativeDots(),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated logo
                  _AnimatedLogo(
                    pulseAnim: _pulseAnim,
                    orbitAnim: _orbitAnim,
                  ),

                  const SizedBox(height: 48),

                  // Title
                  const Text(
                    'Searching for nearby\nproviders...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _tealDark,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Our guardian network is being alerted to your urgent requirement.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Animated dots indicator
                  _AnimatedDots(animation: _dotAnim),

                  const Spacer(flex: 3),

                  // Cancel/back button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel Request',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDecorativeDots() {
    final positions = [
      const Offset(30, 120),
      const Offset(340, 80),
      const Offset(20, 300),
      const Offset(360, 260),
      const Offset(60, 500),
      const Offset(320, 480),
    ];
    return positions.map((pos) {
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
      );
    }).toList();
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _AnimatedLogo extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Animation<double> orbitAnim;

  const _AnimatedLogo({required this.pulseAnim, required this.orbitAnim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer orbit ring
          AnimatedBuilder(
            animation: orbitAnim,
            builder: (_, __) {
              return Transform.rotate(
                angle: orbitAnim.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(130, 130),
                  painter: _OrbitRingPainter(),
                ),
              );
            },
          ),

          // Pulsing background circle
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) {
              return Transform.scale(
                scale: pulseAnim.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D9488).withOpacity(0.12),
                  ),
                ),
              );
            },
          ),

          // Core icon container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0D4F4A),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint = Paint()
      ..color = const Color(0xFF0D9488).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Dashed arc
    const dashCount = 12;
    const dashAngle = math.pi * 2 / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle * 0.6,
        false,
        paint,
      );
    }

    // Bright dot on orbit
    final dotPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.fill;
    final dotX = center.dx + radius * math.cos(0);
    final dotY = center.dy + radius * math.sin(0);
    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedDots extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedDots({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final phase = ((t - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + 0.6 * math.sin(phase * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.5 + 0.5 * scale - 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}