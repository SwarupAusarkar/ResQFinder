// lib/screens/map_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/provider_model.dart';
import 'provider_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Provider> _providers = [];
  List<Provider> _filteredProviders = [];
  String _serviceType = '';
  LatLng? _currentPosition;
  bool _isLoading = true;

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;
  bool _showAvailableOnly = false;
  String _sortBy = 'distance';

  static const _teal = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Initialize map after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeMap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _initializeMap() async {
    _loadProvidersFromArgs();
    await _determinePosition();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadProvidersFromArgs() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _providers = args['providers'] as List<Provider>? ?? [];
      _serviceType = args['serviceType'] as String? ?? 'Service';
      _filteredProviders = List.from(_providers);
      _applyFilters(); // Apply default sorting immediately
    }
  }

  void _applyFilters() {
    List<Provider> result = List.from(_providers);

    if (_searchQuery.isNotEmpty) {
      result = result.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.address.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_showAvailableOnly) {
      result = result.where((p) => p.isAvailable).toList();
    }

    // FIX: Custom Sort - Firebase Providers First, OSM Providers Last
    result.sort((a, b) {
      int aIsOsm = a.id.startsWith('osm_') ? 1 : 0;
      int bIsOsm = b.id.startsWith('osm_') ? 1 : 0;
      
      // If one is Firebase and one is OSM, Firebase wins
      if (aIsOsm != bIsOsm) return aIsOsm.compareTo(bIsOsm);

      // Otherwise, sort by the user's selected preference
      if (_sortBy == 'rating') {
        return b.rating.compareTo(a.rating);
      } else {
        return a.distance.compareTo(b.distance);
      }
    });

    setState(() => _filteredProviders = result);
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { _showErrorDialog('Location services are disabled.'); return; }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { _showErrorDialog('Location permissions are denied.'); return; }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog('Location permissions are permanently denied.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = LatLng(position.latitude, position.longitude));
        // FIX: Removed _mapController.move() here. 
        // The MapOptions initialCenter will handle it when the loading spinner disappears!
      }
    } catch (e) {
      _showErrorDialog('Failed to get location: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Error', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _centerOnUserLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detecting your location...'))
      );
      _determinePosition();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(
        showAvailableOnly: _showAvailableOnly,
        sortBy: _sortBy,
        onApply: (available, sort) {
          setState(() {
            _showAvailableOnly = available;
            _sortBy = sort;
            _applyFilters();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = (_showAvailableOnly ? 1 : 0) + (_sortBy != 'distance' ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _teal))
              : _buildMap(),
          _MapTopOverlay(
            serviceType: _serviceType,
            showSearchBar: _showSearchBar,
            searchController: _searchController,
            onSearchToggle: () => setState(() {
              _showSearchBar = !_showSearchBar;
              if (!_showSearchBar) {
                _searchController.clear();
                _applyFilters();
              }
            }),
            onFilterTap: _showFilterSheet,
            filterCount: filterCount,
          ),
          Positioned(bottom: 24, right: 20, child: _SosButton()),
          Positioned(bottom: 90, right: 20, child: _CenterButton(onTap: _centerOnUserLocation)),
          if (!_isLoading)
            Positioned(bottom: 90, left: 20, child: _ResultsBubble(count: _filteredProviders.length)),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? const LatLng(19.0760, 72.8777),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
            urlTemplate: "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
            userAgentPackageName: "com.cityissues.app"
        ),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
  
    for (final provider in _filteredProviders.reversed) {
      markers.add(Marker(
        width: 52, height: 52,
        point: LatLng(provider.latitude, provider.longitude),
        child: GestureDetector(
            onTap: () => _showProviderBottomSheet(provider),
            child: _ProviderMapPin(provider: provider)
        ),
      ));
    }
    if (_currentPosition != null) {
      markers.add(Marker(
          width: 28, height: 28,
          point: _currentPosition!,
          child: _UserLocationPin()
      ));
    }
    return markers;
  }

  void _showProviderBottomSheet(Provider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProviderBottomSheet(
        provider: provider,
        onViewDetails: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProviderDetailsScreen(),
                  settings: RouteSettings(arguments: provider)
              )
          );
        },
      ),
    );
  }
}

// ── UI Components (Overlays & Widgets) ──────────────────────────────────────────

class _MapTopOverlay extends StatelessWidget {
  final String serviceType;
  final bool showSearchBar;
  final TextEditingController searchController;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilterTap;
  final int filterCount;

  const _MapTopOverlay({
    required this.serviceType, required this.showSearchBar,
    required this.searchController, required this.onSearchToggle,
    required this.onFilterTap, required this.filterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: showSearchBar
                      ? _SearchField(controller: searchController)
                      : _SearchLabel(serviceType: serviceType),
                ),
              ),
              const SizedBox(width: 8),
              _TopBarButton(
                  icon: showSearchBar ? Icons.close_rounded : Icons.search_rounded,
                  onTap: onSearchToggle
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _TopBarButton(icon: Icons.tune_rounded, onTap: onFilterTap),
                  if (filterCount > 0)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(color: Color(0xFF0D9488), shape: BoxShape.circle),
                        child: Center(child: Text('$filterCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchLabel extends StatelessWidget {
  final String serviceType;
  const _SearchLabel({required this.serviceType});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('label'), height: 46,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(Icons.location_on_rounded, size: 18, color: Colors.teal[400]),
        const SizedBox(width: 8),
        Expanded(child: Text('Finding ${serviceType.capitalize()}s...', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('field'), height: 46,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 3))]),
      child: TextField(
        controller: controller, autofocus: true,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0D4F4A)),
        decoration: InputDecoration(
          hintText: 'Search by name or street...', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 18),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 3))]),
        child: Icon(icon, size: 20, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

class _ResultsBubble extends StatelessWidget {
  final int count;
  const _ResultsBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF0D4F4A), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
      child: Text('$count ${count == 1 ? 'Provider' : 'Providers'} Found', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  final bool showAvailableOnly;
  final String sortBy;
  final void Function(bool, String) onApply;
  const _FilterBottomSheet({required this.showAvailableOnly, required this.sortBy, required this.onApply});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late bool _available;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _available = widget.showAvailableOnly;
    _sort = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
            const Text('Filter & Sort', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D4F4A))),
            const SizedBox(height: 20),
            const Text('AVAILABILITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(children: [
                const Expanded(child: Text('Show Available Only', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0D4F4A)))),
                Switch(value: _available, onChanged: (v) => setState(() => _available = v), activeColor: const Color(0xFF0D9488)),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('SORT BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Row(children: [
              _SortChip(label: 'Distance', value: 'distance', selected: _sort, onTap: (v) => setState(() => _sort = v)),
              const SizedBox(width: 10),
              _SortChip(label: 'Rating', value: 'rating', selected: _sort, onTap: (v) => setState(() => _sort = v)),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_available, _sort);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: const Text('Apply Selection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _SortChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF0D4F4A))),
      ),
    );
  }
}

// ── Custom Map Pins ───────────────────────────────────────────────────────────

class _ProviderMapPin extends StatelessWidget {
  final Provider provider;
  const _ProviderMapPin({required this.provider});

  Color get _pinColor {
    if (!provider.isAvailable) return const Color(0xFFDC2626);
    switch (provider.type.toLowerCase()) {
      case 'hospital': return const Color(0xFF0D9488);
      case 'police': return const Color(0xFF1D4ED8);
      case 'ambulance': return const Color(0xFFEA580C);
      default: return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: _pinColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: _pinColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Center(
              child: Icon(
                  provider.type.toLowerCase() == 'police' ? Icons.shield_rounded : Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 20
              )
          ),
        ),
        Positioned(bottom: 0, child: CustomPaint(painter: _PinNubPainter(color: _pinColor), size: const Size(12, 8))),
      ],
    );
  }
}

class _PinNubPainter extends CustomPainter {
  final Color color;
  const _PinNubPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final ui.Path path = ui.Path()..moveTo(0, 0)..lineTo(size.width / 2, size.height)..lineTo(size.width, 0)..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UserLocationPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF3B82F6),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)]
      ),
    );
  }
}

class _ProviderBottomSheet extends StatelessWidget {
  final Provider provider;
  final VoidCallback onViewDetails;
  const _ProviderBottomSheet({required this.provider, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final isAvailable = provider.isAvailable;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -4))]),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
            Row(children: [
              Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF9), borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Icon(Icons.business_rounded, color: Color(0xFF0D9488), size: 30))
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(provider.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(provider.address, style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text('${provider.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Text('${provider.distance.toStringAsFixed(1)} km away', style: const TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
                ]),
              ])),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                          onPressed: onViewDetails,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: const Text('View Full Details', style: TextStyle(fontWeight: FontWeight.w700))
                      )
                  )
              ),
              const SizedBox(width: 12),
              Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.directions_rounded, color: Color(0xFF16A34A), size: 24)
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: const Color(0xFFDC2626), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]),
      child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 3))]),
        child: const Icon(Icons.my_location_rounded, color: Color(0xFF0F172A), size: 22),
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}