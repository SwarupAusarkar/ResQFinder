import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../services/offline_cache_service.dart';

class OfflineRegionPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  
  const OfflineRegionPickerScreen({
    super.key, 
    this.initialLat = 19.0760, // Default to Mumbai
    this.initialLng = 72.8777,
  });

  @override
  State<OfflineRegionPickerScreen> createState() => _OfflineRegionPickerScreenState();
}

class _OfflineRegionPickerScreenState extends State<OfflineRegionPickerScreen> {
  final MapController _mapController = MapController();
  final SearchController _searchController = SearchController();
  LatLng? _selectedLocation;
  double _radiusKm = 20.0;
  bool _isSaving = false;
  Timer? _debounce;
  // NOMINATIM SEARCH LOGIC
  Future<List<Map<String, dynamic>>> _searchAddress(String query) async {
    if (query.length < 3) return [];
    
    // We use Uri.https to ensure the query parameters are encoded correctly
    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '5',
      'countrycodes': 'in', // This locks it to India
    });

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'ResQFinder_App_Project' 
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => {
          'display_name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
        }).toList();
      } else {
        debugPrint("Nominatim Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Search logic failed: $e");
    }
    return [];
  }

  void _moveToLocation(double lat, double lon) {
    final newPos = LatLng(lat, lon);
    setState(() => _selectedLocation = newPos);
    _mapController.move(newPos, 12.0);
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() => _selectedLocation = location);
  }

  Future<void> _saveRegion() async {
    if (_selectedLocation == null) return;

    final nameController = TextEditingController();
    final tripName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Name your Trip"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "e.g., Manali Basecamp"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()), 
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (tripName == null || tripName.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await OfflineCacheService.saveRegion(
        regionName: tripName,
        lat: _selectedLocation!.latitude,
        lng: _selectedLocation!.longitude,
        radiusKm: _radiusKm,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Region cached successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Offline Region"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.initialLat, widget.initialLng),
              initialZoom: 10.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: "com.cityissues.app",
              ),
              if (_selectedLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedLocation!,
                      radius: _radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40, height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),

          // SEARCH BAR UI
          Positioned(
            top: 10, left: 15, right: 15,
            child: SearchAnchor(
              searchController: _searchController,
              builder: (context, controller) {
                return SearchBar(
                  controller: controller,
                  hintText: "Search for a city or region...",
                  onTap: () => controller.openView(),
                  leading: const Icon(Icons.search),
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                );
              },
              suggestionsBuilder: (context, controller) async {
  // 1. Cancel the previous timer if the user is still typing
  if (_debounce?.isActive ?? false) _debounce!.cancel();

  // 2. Create a Completer to return the results after the delay
  Completer<List<Widget>> completer = Completer();

  _debounce = Timer(const Duration(milliseconds: 500), () async {
    final results = await _searchAddress(controller.text);
    
    final widgets = results.map((res) => ListTile(
      title: Text(res['display_name']),
      leading: const Icon(Icons.location_on),
      onTap: () {
        _moveToLocation(res['lat'], res['lon']);
        controller.closeView(res['display_name']);
      },
    )).toList();
    
    completer.complete(widgets);
  });

  return await completer.future;
},
            ),
          ),
          
          if (_selectedLocation == null)
            const Positioned(
              top: 80, left: 20, right: 20,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Search above or tap on map to pin.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),

          if (_selectedLocation != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Search Radius: ${_radiusKm.toInt()} km", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Slider(
                      value: _radiusKm,
                      min: 5, max: 100, divisions: 19,
                      label: "${_radiusKm.toInt()} km",
                      onChanged: (val) => setState(() => _radiusKm = val),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveRegion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800], foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Download Data for Region"),
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}