// lib/screens/provider_list_screen.dart
import 'dart:async';
import 'package:emergency_res_loc_new/screens/OfferApprovalScreen.dart';
import 'package:emergency_res_loc_new/widgets/CustomNavigation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/inventory_item_model.dart';
import '../models/provider_model.dart';
import '../data/data_service.dart';
import '../widgets/provider_card.dart';
import '../data/live_data_service.dart';
import '../screens/send_request_screen.dart';

class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  // ── State ────────────────────────────────────────────────────────────────────
  List<Provider> _allProviders = [];
  List<Provider> _filteredProviders = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _serviceType = '';
  String _sortBy = 'distance';
  bool _showAvailableOnly = true;
  Position? _currentPosition;
  double _selectedRadius = 50000;

  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';
  Timer? _searchDebouncer;
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  final List<String> _commonServices = [
    'ICU Bed', 'Emergency Surgery', 'Ambulance', 'Blood Bank', 'X-Ray',
    'MRI Scan', 'CT Scan', 'Dialysis', 'Oxygen Cylinder', 'Ventilator',
    'Emergency Medicine', 'Pediatric Care', 'Cardiology', 'Neurology',
    'Orthopedic', '24/7 Pharmacy',
  ];

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const _teal = Color(0xFF0D9488);
  static const _bgColor = Color(0xFFF0FDF9);

  Color get _serviceColor => _teal;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadProviders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  // ── Search Logic (unchanged) ──────────────────────────────────────────────────
  void _onSearchTextChanged() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      setState(() {
        _searchSuggestions = _commonServices
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .take(5)
            .toList();
        _showSuggestions = true;
      });
    } else {
      setState(() { _showSuggestions = false; _searchSuggestions = []; });
    }
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() { _currentSearchQuery = query; _isSearching = query.isNotEmpty; _showSuggestions = false; });
    if (query.isEmpty) { setState(() { _filteredProviders = List.from(_allProviders); }); _applyFiltersAndSort(); return; }
    try {
      setState(() => _isLoading = true);
      final lowerQuery = query.toLowerCase();
      List<Provider> searchResults = _allProviders.where((p) {
        return p.name.toLowerCase().contains(lowerQuery) ||
            p.inventory.any((item) => item.name.toLowerCase().contains(lowerQuery));
      }).toList();
      if (searchResults.isEmpty) {
        try {
          searchResults = await LiveDataService.searchProvidersByService(
            service: query,
            latitude: _currentPosition?.latitude ?? 19.0760,
            longitude: _currentPosition?.longitude ?? 72.8777,
          );
          if (_currentPosition != null) {
            searchResults = searchResults.map((p) {
              final d = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, p.latitude, p.longitude);
              return p.copyWith(distance: d / 1000);
            }).toList();
          }
        } catch (e) { debugPrint("Live search failed: $e"); }
      }
      if (mounted) { setState(() { _filteredProviders = searchResults; _isLoading = false; }); _applyFiltersAndSort(); }
    } catch (e) { if (mounted) { setState(() => _isLoading = false); _showErrorSnackBar('Search failed: $e'); } }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() => _showSuggestions = false);
    _performSearch(suggestion);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() { _currentSearchQuery = ''; _isSearching = false; _showSuggestions = false; _filteredProviders = List.from(_allProviders); });
    _applyFiltersAndSort();
  }

  // ── Data loading (unchanged) ─────────────────────────────────────────────────
  Future<void> _initializeAndLoadProviders() async {
    await _determinePosition();
    await _loadProviders();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { _showErrorSnackBar('Location services are disabled.'); return; }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { _showErrorSnackBar('Location permissions are denied.'); return; }
    }
    if (permission == LocationPermission.deniedForever) { _showErrorSnackBar('Location permissions are permanently denied.'); return; }
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = position);
    } catch (e) { _showErrorSnackBar('Could not get current location.'); }
  }

  Future<void> _loadProviders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _serviceType = args?['serviceType'] ?? 'hospital';
      List<Provider> providers;
      try {
        providers = await LiveDataService.fetchProviders(
          serviceType: _serviceType,
          latitude: _currentPosition?.latitude ?? 19.0760,
          longitude: _currentPosition?.longitude ?? 72.8777,
        );
      } catch (e) { debugPrint("Live data failed: $e"); providers = await DataService.getProvidersByType(_serviceType); }
      if (_currentPosition != null) {
        providers = providers.map((p) {
          final d = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, p.latitude, p.longitude);
          return p.copyWith(distance: d / 1000);
        }).toList();
      }
      if (mounted) { setState(() { _allProviders = providers; _isLoading = false; }); _applyFiltersAndSort(); }
    } catch (e) { if (mounted) { setState(() => _isLoading = false); _showErrorSnackBar('Failed to load providers: $e'); } }
  }

  void _applyFiltersAndSort() {
    setState(() {
      List<Provider> temp = _isSearching ? List.from(_filteredProviders) : List.from(_allProviders);
      if (_currentPosition != null) temp = temp.where((p) => (p.distance * 1000) <= _selectedRadius).toList();
      if (_showAvailableOnly) temp = temp.where((p) => p.isAvailable).toList();
      
      // FIX: Force Firebase providers to the TOP of the ListView
      temp.sort((a, b) {
        bool aIsOsm = a.id.startsWith('osm_');
        bool bIsOsm = b.id.startsWith('osm_');
        
        // If 'a' is Firebase and 'b' is OSM, 'a' goes first (-1)
        if (!aIsOsm && bIsOsm) return -1;
        // If 'a' is OSM and 'b' is Firebase, 'b' goes first (1)
        if (aIsOsm && !bIsOsm) return 1;

        // If they are BOTH Firebase or BOTH OSM, sort them normally by the user's choice
        switch (_sortBy) {
          case 'rating': return b.rating.compareTo(a.rating);
          case 'availability': 
            if (a.isAvailable == b.isAvailable) return 0;
            return a.isAvailable ? -1 : 1;
          case 'distance':
          default:
            return a.distance.compareTo(b.distance);
        }
      });
      
      _filteredProviders = temp;
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────────
  void _navigateToProviderDetails(Provider provider) {
    Navigator.pushNamed(context, '/provider-details', arguments: provider);
  }

  void _openMapView() {
    Navigator.pushNamed(context, '/map', arguments: {
      'providers': _filteredProviders,
      'serviceType': _serviceType,
      'searchQuery': _currentSearchQuery,
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  String _getScreenTitle() {
    switch (_serviceType.toLowerCase()) {
      case 'hospital': return 'Find Care';
      case 'police': return 'Police Stations';
      case 'ambulance': return 'Ambulance Services';
      default: return 'Find Care';
    }
  }

  String _getSortTitle(String s) {
    switch (s) {
      case 'distance': return 'Distance';
      case 'rating': return 'Rating';
      case 'availability': return 'Availability';
      default: return s;
    }
  }

  IconData _getServiceIcon() {
    switch (_serviceType.toLowerCase()) {
      case 'hospital': return Icons.local_hospital;
      case 'police': return Icons.local_police;
      case 'ambulance': return Icons.emergency;
      default: return Icons.emergency_share;
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: _serviceColor,
      action: SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _initializeAndLoadProviders),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _SearchBarSection(
            controller: _searchController,
            isSearching: _isSearching,
            serviceColor: _serviceColor,
            onClear: _clearSearch,
            onMapTap: _openMapView,
          ),
          if (_showSuggestions)
            _SuggestionsDropdown(
              suggestions: _searchSuggestions,
              onTap: _selectSuggestion,
            ),
          _FilterChipsBar(
            showAvailableOnly: _showAvailableOnly,
            selectedRadius: _selectedRadius,
            sortBy: _sortBy,
            serviceColor: _serviceColor,
            providerCount: _filteredProviders.length,
            isSearching: _isSearching,
            searchQuery: _currentSearchQuery,
            onAvailableToggle: () { setState(() => _showAvailableOnly = !_showAvailableOnly); _applyFiltersAndSort(); },
            onRadiusChanged: (r) { setState(() => _selectedRadius = r); _applyFiltersAndSort(); },
            onFilterTap: _showFilterDialog,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _filteredProviders.isNotEmpty
          ? _SosFloatingButton(onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => SendRequestScreen(
          inventoryItem: InventoryItem(name: 'Select Item', quantity: 0, unit: 'Units', lastUpdated: DateTime.now()),
        )));
      })
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: Text(
        _getScreenTitle(),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.checklist_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApprovalScreen())),
          tooltip: 'Requests',
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A)),
          onPressed: _showFilterDialog,
          tooltip: 'Filter & Sort',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    if (_filteredProviders.isEmpty) {
      return _EmptyState(
        isSearching: _isSearching,
        searchQuery: _currentSearchQuery,
        serviceIcon: _getServiceIcon(),
        onClearSearch: _clearSearch,
        onRefresh: _isSearching ? () => _performSearch(_currentSearchQuery) : _loadProviders,
      );
    }
    return RefreshIndicator(
      color: _teal,
      onRefresh: _isSearching ? () => _performSearch(_currentSearchQuery) : _loadProviders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filteredProviders.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ProviderCard(
              provider: _filteredProviders[index],
              onTap: () => _navigateToProviderDetails(_filteredProviders[index]),
              searchQuery: _currentSearchQuery,
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Filter & Sort', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by Status', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('Show available only'),
                  subtitle: const Text('Hide busy providers'),
                  value: _showAvailableOnly,
                  activeColor: _teal,
                  onChanged: (v) => setDialogState(() => _showAvailableOnly = v ?? false),
                ),
                const Divider(),
                const Text('Filter by Distance', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [5000, 10000, 25000, 50000].map((radius) {
                    return ChoiceChip(
                      label: Text(radius >= 50000 ? 'All' : '${radius ~/ 1000} km'),
                      selected: _selectedRadius == radius.toDouble(),
                      selectedColor: _teal.withOpacity(0.2),
                      onSelected: (selected) => setDialogState(() => _selectedRadius = radius.toDouble()),
                    );
                  }).toList(),
                ),
                const Divider(),
                const Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold)),
                ...['distance', 'rating', 'availability'].map((option) => RadioListTile<String>(
                  title: Text(_getSortTitle(option)),
                  value: option,
                  groupValue: _sortBy,
                  activeColor: _teal,
                  onChanged: (value) => setDialogState(() => _sortBy = value ?? 'distance'),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); _applyFiltersAndSort(); },
              style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Decomposed UI Components ──────────────────────────────────────────────────

class _SearchBarSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final Color serviceColor;
  final VoidCallback onClear;
  final VoidCallback onMapTap;

  const _SearchBarSection({
    required this.controller,
    required this.isSearching,
    required this.serviceColor,
    required this.onClear,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Search hospitals, clinics...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(icon: Icon(Icons.close_rounded, color: Colors.grey[400], size: 18), onPressed: onClear)
                      : Icon(Icons.mic_rounded, color: Colors.grey[400], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Map toggle button
          GestureDetector(
            onTap: onMapTap,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: serviceColor.withOpacity(0.3)),
              ),
              child: Icon(Icons.map_rounded, color: serviceColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsDropdown extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;

  const _SuggestionsDropdown({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (context, i) => ListTile(
          dense: true,
          leading: const Icon(Icons.medical_services_rounded, size: 16, color: Color(0xFF0D9488)),
          title: Text(suggestions[i], style: const TextStyle(fontSize: 13)),
          onTap: () => onTap(suggestions[i]),
        ),
      ),
    );
  }
}

class _FilterChipsBar extends StatelessWidget {
  final bool showAvailableOnly;
  final double selectedRadius;
  final String sortBy;
  final Color serviceColor;
  final int providerCount;
  final bool isSearching;
  final String searchQuery;
  final VoidCallback onAvailableToggle;
  final void Function(double) onRadiusChanged;
  final VoidCallback onFilterTap;

  const _FilterChipsBar({
    required this.showAvailableOnly,
    required this.selectedRadius,
    required this.sortBy,
    required this.serviceColor,
    required this.providerCount,
    required this.isSearching,
    required this.searchQuery,
    required this.onAvailableToggle,
    required this.onRadiusChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result count
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '$providerCount provider${providerCount == 1 ? '' : 's'} · Available · Sort: ${_sortTitle(sortBy)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: 'Available Now',
                  icon: Icons.check_circle_rounded,
                  isActive: showAvailableOnly,
                  activeColor: serviceColor,
                  onTap: onAvailableToggle,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Near Me',
                  icon: Icons.near_me_rounded,
                  isActive: false,
                  activeColor: serviceColor,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: '${selectedRadius >= 50000 ? 'All' : '${selectedRadius ~/ 1000} km'}',
                  icon: Icons.radio_button_checked_rounded,
                  isActive: selectedRadius < 50000,
                  activeColor: serviceColor,
                  onTap: onFilterTap,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Blood Av.',
                  icon: Icons.bloodtype_rounded,
                  isActive: false,
                  activeColor: serviceColor,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sortTitle(String s) {
    switch (s) {
      case 'distance': return 'Distance';
      case 'rating': return 'Rating';
      case 'availability': return 'Availability';
      default: return s;
    }
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isActive ? [BoxShadow(color: activeColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final String searchQuery;
  final IconData serviceIcon;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;

  const _EmptyState({
    required this.isSearching,
    required this.searchQuery,
    required this.serviceIcon,
    required this.onClearSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(isSearching ? Icons.search_off_rounded : serviceIcon,
                  size: 40, color: const Color(0xFF0D9488)),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No results for "$searchQuery"' : 'No providers found',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching ? 'Try a different search term.' : 'Try adjusting your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            if (isSearching)
              ElevatedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF0D9488)), foregroundColor: const Color(0xFF0D9488), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosFloatingButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SosFloatingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text('SOS',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5)),
        ),
      ),
    );
  }
}