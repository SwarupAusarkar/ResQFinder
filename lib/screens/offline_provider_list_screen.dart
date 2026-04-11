import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_model.dart';
import '../widgets/provider_card.dart';

class OfflineProviderListScreen extends StatefulWidget {
  final String regionName;
  final double lat;
  final double lng;
  final double radiusKm;

  const OfflineProviderListScreen({
    super.key,
    required this.regionName,
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });

  @override
  State<OfflineProviderListScreen> createState() => _OfflineProviderListScreenState();
}

class _OfflineProviderListScreenState extends State<OfflineProviderListScreen> {
  bool _isLoading = true;
  List<Provider> _offlineProviders = []; // FIX: Now stores actual Provider objects

  static const _teal = Color(0xFF0D9488);
  static const _bgColor = Color(0xFFF0FDF9);

  @override
  void initState() {
    super.initState();
    _loadCachedProviders();
  }

  Future<void> _loadCachedProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final jsonStr = prefs.getString('offline_api_${widget.regionName}');
      
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        
        if (mounted) {
          setState(() {
            _offlineProviders = decoded.map((e) {
              final map = Map<String, dynamic>.from(e);
              if (map['fullName'] == null && map['name'] != null) {
                map['fullName'] = map['name'];
              }
              return Provider.fromJson(map['id'] ?? '', map);
            }).toList();
            
            _offlineProviders.sort((a, b) {
              bool aIsOsm = a.id.startsWith('osm_');
              bool bIsOsm = b.id.startsWith('osm_');

              if (!aIsOsm && bIsOsm) return -1;
              if (aIsOsm && !bIsOsm) return 1;

              return a.distance.compareTo(b.distance);
            });
            
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to parse offline data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offline Data',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _teal),
            ),
            Text(
              widget.regionName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          // FIX: Added the Map Button to view cached providers on the MapScreen
          if (_offlineProviders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_rounded, color: _teal),
              tooltip: 'View on Map',
              onPressed: () {
                Navigator.pushNamed(context, '/map', arguments: {
                  'providers': _offlineProviders,
                  'serviceType': 'All Offline',
                  'searchQuery': '',
                });
              },
            ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text('OFFLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _offlineProviders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _offlineProviders.length,
                  itemBuilder: (context, index) {
                    final provider = _offlineProviders[index];
                    
                    // FIX: Reused your standard ProviderCard from the rest of the app
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ProviderCard(
                        provider: provider,
                        searchQuery: '',
                        onTap: () {
                          // Navigates directly to standard provider details page!
                          Navigator.pushNamed(
                            context, 
                            '/provider-details', 
                            arguments: provider
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No Cached Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("There are no providers cached for this region.", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}