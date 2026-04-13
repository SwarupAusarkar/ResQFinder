// lib/widgets/provider_card.dart
import 'package:flutter/material.dart';
import '../models/provider_model.dart';

/// Reusable card for displaying provider info, matching the new design system.
/// Decomposed into small private component methods for readability.
class ProviderCard extends StatelessWidget {
  final Provider provider;
  final VoidCallback? onTap;
  final String? searchQuery;

  const ProviderCard({
    super.key,
    required this.provider,
    this.onTap,
    this.searchQuery,
  });

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const _teal = Color(0xFF0D9488);
  static const _lightBg = Color(0xFFF0FDF9);
  static const _cardRadius = Radius.circular(20);

  Color get _typeColor {
    switch (provider.type.toLowerCase()) {
      case 'hospital':
        return const Color(0xFF0D9488);
      case 'police':
        return const Color(0xFF1D4ED8);
      case 'ambulance':
        return const Color(0xFFEA580C);
      default:
        return Colors.grey;
    }
  }

  // ── Root build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(_cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.all(_cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProviderCardHeader(provider: provider, typeColor: _typeColor),
              if (provider.inventory.isNotEmpty)
                _ProviderCardServices(
                  provider: provider,
                  typeColor: _typeColor,
                  searchQuery: searchQuery,
                ),
              // _ProviderCardFooter(
              //   provider: provider,
              //   typeColor: _typeColor,
              //   onCallTap: () => _showPhoneDialog(context),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Call Provider',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Call ${provider.name} at ${provider.phone}?\n\nThis is a demo app – no actual call will be made.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${provider.name}...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

/// Top section: hospital image placeholder, name, address, availability badge
class _ProviderCardHeader extends StatelessWidget {
  final Provider provider;
  final Color typeColor;

  const _ProviderCardHeader({
    required this.provider,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with emoji icon
          _ProviderThumbnail(
              iconPath: provider.iconPath, typeColor: typeColor),
          const SizedBox(width: 14),

          // Name + address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AvailabilityBadge(isAvailable: provider.isAvailable),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        provider.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _RatingRow(
                  rating: provider.rating,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderThumbnail extends StatelessWidget {
  final String iconPath;
  final Color typeColor;

  const _ProviderThumbnail({required this.iconPath, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: typeColor.withOpacity(0.15), width: 1),
      ),
      child: Center(
        child: Text(iconPath, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final bg = isAvailable
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'AVAILABLE' : 'LIMITED',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;

  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A)),
        ),
        // if (consultation > 0) ...[
        //   const SizedBox(width: 10),
        //   Text(
        //     '₹$consultation Consultation',
        //     style: const TextStyle(
        //         fontSize: 12,
        //         fontWeight: FontWeight.w500,
        //         color: Color(0xFF0D9488)),
        //   ),
        // ],
      ],
    );
  }
}

/// Services / inventory chips section
class _ProviderCardServices extends StatelessWidget {
  final Provider provider;
  final Color typeColor;
  final String? searchQuery;

  const _ProviderCardServices({
    required this.provider,
    required this.typeColor,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = provider.inventory.take(4).toList();
    final hasMore = provider.inventory.length > 4;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...displayItems.map((item) => _ServiceChip(
            label: item.name,
            typeColor: typeColor,
            searchQuery: searchQuery,
          )),
          if (hasMore)
            _ServiceChip(
              label: '+${provider.inventory.length - 4} more',
              typeColor: Colors.grey,
              searchQuery: null,
              isMuted: true,
            ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final Color typeColor;
  final String? searchQuery;
  final bool isMuted;

  const _ServiceChip({
    required this.label,
    required this.typeColor,
    this.searchQuery,
    this.isMuted = false,
  });

  bool get _isHighlighted =>
      !isMuted &&
          searchQuery != null &&
          searchQuery!.isNotEmpty &&
          label.toLowerCase().contains(searchQuery!.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final bg = _isHighlighted
        ? const Color(0xFFFEF3C7)
        : isMuted
        ? Colors.grey.withOpacity(0.08)
        : typeColor.withOpacity(0.08);
    final border = _isHighlighted
        ? const Color(0xFFF59E0B)
        : isMuted
        ? Colors.grey.withOpacity(0.2)
        : typeColor.withOpacity(0.2);
    final textColor = _isHighlighted
        ? const Color(0xFF92400E)
        : isMuted
        ? Colors.grey
        : typeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: _isHighlighted ? FontWeight.w700 : FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

/// Bottom footer: distance, directions button, call button
class _ProviderCardFooter extends StatelessWidget {
  final Provider provider;
  final Color typeColor;
  final VoidCallback onCallTap;

  const _ProviderCardFooter({
    required this.provider,
    required this.typeColor,
    required this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFE),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          // Distance chip
          _FooterChip(
            icon: Icons.near_me_rounded,
            label: '${provider.distance.toStringAsFixed(1)} km',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 8),

          // Directions CTA
          Expanded(
            child: _DirectionsButton(typeColor: typeColor),
          ),
          const SizedBox(width: 8),

          // Call button
          _CallButton(onTap: onCallTap),
        ],
      ),
    );
  }
}
class ProviderName extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
class _FooterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FooterChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionsButton extends StatelessWidget {
  final Color typeColor;

  const _DirectionsButton({required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.navigation_rounded, size: 14, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'Directions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
        ),
        child: const Icon(Icons.phone_rounded,
            size: 18, color: Color(0xFF16A34A)),
      ),
    );
  }
}