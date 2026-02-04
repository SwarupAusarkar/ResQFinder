import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/provider_model.dart';
import 'provider_details_screen.dart';

// Map screen showing providers and user's location on OpenStreetMap
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Provider> _providers = [];
  String _serviceType = '';
  LatLng? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to safely access ModalRoute
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    _loadProvidersFromArgs();
    await _determinePosition();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _loadProvidersFromArgs() {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _providers = args['providers'] as List<Provider>? ?? [];
        _serviceType = args['serviceType'] as String? ?? 'all';
      }
  }

  /// Determine the current position of the device.
  /// When location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Location services are disabled. Please enable them in your settings.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog('Location permissions are denied. Please enable them in your settings.');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog('Location permissions are permanently denied, we cannot request permissions.');
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
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
        title: const Text('Location Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_serviceType.capitalize()} Map'),
        backgroundColor: _getServiceColor(),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition ?? const LatLng(19.0760, 72.8777), // Default to Mumbai
                initialZoom: 13.0,
              ),
              children: [
                // TileLayer(
                //   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                //   userAgentPackageName: 'com.example.emergency_resource_locator',
                // ),
                TileLayer(
                  urlTemplate: "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.cityissues.app",
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUserLocation,
        backgroundColor: _getServiceColor(),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Add provider markers
    for (final provider in _providers) {
      markers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(provider.latitude, provider.longitude),
          child: GestureDetector(
            onTap: () => _showProviderBottomSheet(provider),
            child: Text(provider.iconPath, style: const TextStyle(fontSize: 30)),
          ),
        ),
      );
    }

    // Add user location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          width: 24.0,
          height: 24.0,
          point: _currentPosition!,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }
  
  void _centerOnUserLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User location not available yet.')),
      );
    }
  }
  
  Color _getServiceColor() {
    switch (_serviceType.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'ambulance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showProviderBottomSheet(Provider provider) {
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
              Text(provider.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(provider.address),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   ElevatedButton(
                    child: const Text('View Details'),
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProviderDetailsScreen(),
                          settings: RouteSettings(arguments: provider),
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}