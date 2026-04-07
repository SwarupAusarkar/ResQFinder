// lib/screens/MainWrapper.dart
import 'package:emergency_res_loc_new/screens/provider_main_screen.dart';
import 'package:emergency_res_loc_new/screens/provider_profile_edit_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/customNavigation.dart';
import '../constants.dart';
import '../screens/provider_dashboard_screen.dart';
import '../screens/manage_inventory_screen.dart';
import '../screens/ProviderHistoryPage.dart';

class MainWrapper extends StatefulWidget {
  final bool isProvider;
  final int initialIndex; // NEW: Start at specific tab

  const MainWrapper({
    super.key,
    required this.isProvider,
    this.initialIndex = 0,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Define screens for each user type
  List<Widget> get _providerScreens => const [
    ProviderMainScreen(),
    ManageInventoryScreen(),
    HistoryPage(),
    ProviderProfileEditScreen(),
  ];

  List<Widget> get _requesterScreens => const [
    // RequesterHomeScreen(),
    // RequesterDashboardScreen(),
    // RequesterHistoryScreen(),
    // RequesterProfileScreen(),
    // RequesterSettingsScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) return; // Already on this tab

    setState(() {
      _currentIndex = index;
    });

    // Smooth page transition
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );

    // Trigger animation
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final currentTabs = widget.isProvider ? providerTabs : requesterTabs;
    final currentScreens = widget.isProvider ? _providerScreens : _requesterScreens;

    return WillPopScope(
      // Handle back button - go to first tab
      onWillPop: () async {
        if (_currentIndex != 0) {
          _onTabTapped(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Only navigate via tabs
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: currentScreens.length,
          itemBuilder: (context, index) {
            return FadeTransition(
              opacity: _animationController,
              child: currentScreens[index],
            );
          },
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          tabs: currentTabs,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}