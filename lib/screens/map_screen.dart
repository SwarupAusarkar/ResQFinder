import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/provider_model.dart';
import '../data/data_service.dart';

// Map screen showing providers on OpenStreetMap
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Provider> _providers = [];
  bool _isLoading = true;
  String _serviceType = '';

  // Mumbai city center coordinates
  final LatLng _mapCenter = const LatLng(19.0760, 72.8777);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapData();
  }

  // Load map data from arguments or fetch all providers
  Future<void> _loadMapData() async {
    try {
      // Try to get providers from navigation arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null && args['providers'] != null) {
        // Use providers passed from provider list screen
        _providers = args['providers'] as List<Provider>;
        _serviceType = args['serviceType'] ?? '';
      } else {
        // Load all providers if no specific ones passed
        _providers = await DataService.loadProviders();
        _serviceType = 'all';
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load map data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getMapTitle()),
        backgroundColor: _getServiceColor(),
        foregroundColor: Colors.white,
        actions: [
          if (_providers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: _centerMapOnProviders,
              tooltip: 'Center on providers',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
              ? _buildEmptyState()
              : Stack(
                  children: [
                    // Map widget
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _mapCenter,
                        initialZoom: 11.0, // Adjusted for Mumbai city view
                        minZoom: 8.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        // OpenStreetMap tile layer
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.emergency_resource_locator',
                          maxZoom: 18,
                        ),
                        
                        // Provider markers
                        MarkerLayer(
                          markers: _buildMarkers(),
                        ),
                      ],
                    ),
                    
                    // Provider info panel at bottom
                    if (_providers.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildProviderInfoPanel(),
                      ),
                  ],
                ),
      floatingActionButton: _providers.isNotEmpty
          ? FloatingActionButton(
              onPressed: _centerMapOnProviders,
              backgroundColor: _getServiceColor(),
              child: const Icon(Icons.my_location, color: Colors.white),
            )
          : null,
    );
  }

  // Build markers for each provider
  List<Marker> _buildMarkers() {
    return _providers.map((provider) {
      return Marker(
        point: LatLng(provider.latitude, provider.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showProviderBottomSheet(provider),
          child: Container(
            decoration: BoxDecoration(
              color: provider.isAvailable ? _getProviderColor(provider.type) : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                provider.iconPath,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // Build provider info panel at bottom
  Widget _buildProviderInfoPanel() {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _getServiceColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_providers.length} providers in Mumbai',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap markers for details',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _providers.length,
              itemBuilder: (context, index) {
                final provider = _providers[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => _showProviderBottomSheet(provider),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Text(
                              provider.iconPath,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    provider.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${provider.distance.toStringAsFixed(1)} km away',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No providers to show on map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a service type to view providers in Mumbai',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show provider details in bottom sheet
  void _showProviderBottomSheet(Provider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Provider details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getProviderColor(provider.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              provider.iconPath,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: provider.isAvailable ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    provider.isAvailable ? 'Available' : 'Busy',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildDetailRow(Icons.location_on, 'Address', provider.address),
                      _buildDetailRow(Icons.phone, 'Phone', provider.phone),
                      _buildDetailRow(Icons.near_me, 'Distance', '${provider.distance.toStringAsFixed(1)} km'),
                      _buildDetailRow(Icons.star, 'Rating', '${provider.rating}/5'),
                      
                      if (provider.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(
                                  context,
                                  '/provider-details',
                                  arguments: provider,
                                );
                              },
                              icon: const Icon(Icons.info),
                              label: const Text('View Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getProviderColor(provider.type),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showCallDialog(provider);
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build detail row widget
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Center map on providers
  void _centerMapOnProviders() {
    if (_providers.isEmpty) return;

    if (_providers.length == 1) {
      // Center on single provider
      final provider = _providers.first;
      _mapController.move(LatLng(provider.latitude, provider.longitude), 15.0);
    } else {
      // Calculate bounds for multiple providers
      double minLat = _providers.first.latitude;
      double maxLat = _providers.first.latitude;
      double minLng = _providers.first.longitude;
      double maxLng = _providers.first.longitude;

      for (final provider in _providers) {
        minLat = minLat < provider.latitude ? minLat : provider.latitude;
        maxLat = maxLat > provider.latitude ? maxLat : provider.latitude;
        minLng = minLng < provider.longitude ? minLng : provider.longitude;
        maxLng = maxLng > provider.longitude ? maxLng : provider.longitude;
      }

      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    }
  }

  // Get map title based on service type
  String _getMapTitle() {
    switch (_serviceType.toLowerCase()) {
      case 'hospital':
        return 'Mumbai Hospitals';
      case 'police':
        return 'Mumbai Police Stations';
      case 'ambulance':
        return 'Mumbai Ambulance Services';
      default:
        return 'Mumbai Emergency Services';
    }
  }

  // Get service-specific color
  Color _getServiceColor() {
    switch (_serviceType.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'ambulance':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Get provider type specific color
  Color _getProviderColor(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'ambulance':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Show call dialog
  void _showCallDialog(Provider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Provider'),
        content: Text(
          'Call ${provider.name} at ${provider.phone}?\n\n'
          'This is a demo app - no actual call will be made.',
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
                SnackBar(content: Text('Calling ${provider.name}...')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadMapData,
        ),
      ),
    );
  }
}