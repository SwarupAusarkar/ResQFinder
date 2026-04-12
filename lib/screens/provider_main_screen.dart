import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../widgets/customNavigation.dart';

// Import your screens
import 'newRequestPage.dart';
import 'myOffersPage.dart';
import 'ProviderHistoryPage.dart';
import 'provider_profile_edit_screen.dart';
import '../widgets/inventoryBottomSheet.dart';

class ProviderMainScreen extends StatefulWidget {
  final int initialTab;

  const ProviderMainScreen({super.key, this.initialTab = 0});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late AnimationController _animationController;

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAvailability();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    // BUG FIX: Changed 'users' to 'providers'
    final doc = await _firestore.collection('providers').doc(uid).get();
    if (mounted) {
      setState(() {
        _isAvailable = doc.data()?['isAvailable'] ?? true;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isAvailable = value);

    try {
      // BUG FIX: Changed 'users' to 'providers'
      await _firestore.collection('providers').doc(uid).update({
        'isAvailable': value,
        'availabilityUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(value ? Icons.check_circle : Icons.cancel, color: Colors.white),
                const SizedBox(width: 12),
                Text(value ? 'You are now available' : 'You are now offline'),
              ],
            ),
            backgroundColor: value ? primaryColor : Colors.grey[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating availability: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isAvailable = !value); // rollback on error
      }
    }
  }

  void _onNavTap(int index) {
    if (index == 1) {
      _showInventorySheet();
      return;
    }

    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward(from: 0.0);
  }

  void _showInventorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const InventoryBottomSheet(),
    );
  }

  List<Widget> get _pages => const [
    NewRequestsPage(),       
    MyOffersPage(),          
    SizedBox.shrink(),       
    HistoryPage(),           
    ProviderProfileEditScreen(), 
  ];

  String _getTitle() {
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 2: return 'History';
      case 3: return 'Profile';
      default: return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    // BUG FIX: Upgraded WillPopScope to PopScope
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 0) {
          _onNavTap(0);
        }
      },
      child: Scaffold(
        appBar: _currentIndex != 4 
            ? AppBar(
                title: Text(_getTitle(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                centerTitle: false,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0.5,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isAvailable ? primaryColor.withOpacity(0.1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isAvailable ? primaryColor : Colors.grey[400]!, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: _isAvailable ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: _isAvailable ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isAvailable ? 'Available' : 'Offline',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isAvailable ? primaryColor : Colors.grey[600]),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 20, width: 36,
                          child: Switch(
                            value: _isAvailable,
                            onChanged: _toggleAvailability,
                            activeColor: primaryColor,
                            activeTrackColor: primaryColor.withOpacity(0.3),
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[300],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : null,
        body: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (index == 2) return;
            setState(() => _currentIndex = index);
          },
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            return FadeTransition(
              opacity: _animationController.drive(CurveTween(curve: Curves.easeInOut)),
              child: _pages[index],
            );
          },
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          tabs: providerTabs,
        ),
      ),
    );
  }
}