import 'package:flutter/material.dart';

// Create a simple model to hold Tab data
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> items; // Dynamic list of items

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items, // Pass any number of items here
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding makes it "Floating"
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Rounded floating look
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            return _buildNavItem(
              item: items[index],
              index: index,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NavItem item,
    required int index,
  }) {
    final isActive = currentIndex == index;
    const activeColor = Color(0xFF00897B);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // Translucent shade for active tab
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? activeColor : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}