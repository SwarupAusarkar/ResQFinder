import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderMapScreen extends StatefulWidget {
  const ProviderMapScreen({super.key});

  @override
  State<ProviderMapScreen> createState() => _ProviderMapScreenState();
}

class _ProviderMapScreenState extends State<ProviderMapScreen> {
  final MapController _mapController = MapController();

  LatLng? _currentPosition;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await _determinePosition();
    await _fetchNearbyRequests();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();

    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _fetchNearbyRequests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('emergency_requests')
        .where('status', isEqualTo: 'pending')
        .get();

    _requests = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'latitude': doc['latitude'],
        'longitude': doc['longitude'],
        'itemName': doc['itemName'],
        'locationName': doc['locationName'],
      };
    }).toList();
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Request markers
    for (final request in _requests) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: LatLng(request['latitude'], request['longitude']),
          child: GestureDetector(
            onTap: () => _showRequestBottomSheet(request),
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 35,
            ),
          ),
        ),
      );
    }

    // Provider current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          width: 24,
          height: 24,
          point: _currentPosition!,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showRequestBottomSheet(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request['itemName'],
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(request['locationName']),
              const SizedBox(height: 16),
              const Text(
                "Open Provider Dashboard to accept this request.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  void _centerOnUserLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Emergency Requests"),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter:
          _currentPosition ?? const LatLng(19.0760, 72.8777),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate:
            "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
            userAgentPackageName: "com.cityissues.app",
          ),
          MarkerLayer(markers: _buildMarkers()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUserLocation,
        backgroundColor: const Color(0xFF00897B),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}