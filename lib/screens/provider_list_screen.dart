import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/provider_model.dart';
import '../data/data_service.dart';
import '../widgets/provider_card.dart';
import '../data/live_data_service.dart';

// Screen showing list of providers for selected service type
class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  List<Provider> _providers = [];
  List<Provider> _filteredProviders = [];
  bool _isLoading = true;
  String _serviceType = '';
  String _sortBy = 'distance'; // distance, rating, availability
  bool _showAvailableOnly = false;
  Position? _currentPosition;
  double _selectedRadius = 50000; // Default to 50km to show all initially

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to safely access ModalRoute
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadProviders();
    });
  }

  Future<void> _initializeAndLoadProviders() async {
    await _determinePosition();
    await _loadProviders();
  }
  
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permissions are denied.');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar('Location permissions are permanently denied.');
      return;
    } 

    try {
      final position = await Geolocator.getCurrentPosition();
       if(mounted){
        setState(() {
          _currentPosition = position;
        });
       }
    } catch(e) {
      _showErrorSnackBar('Could not get current location.');
    }
  }


  // Load providers based on service type from navigation arguments
  Future<void> _loadProviders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

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
      } catch (e) {
        debugPrint("⚠️ Live data failed, falling back to static: $e");
        providers = await DataService.getProvidersByType(_serviceType);
      }

      if (_currentPosition != null) {
        providers = providers.map((provider) {
          final distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            provider.latitude,
            provider.longitude,
          );
          return provider.copyWith(distance: distanceInMeters / 1000); // Convert to km
        }).toList();
      }

      if (mounted) {
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load providers: $e');
      }
    }
  }


  // Apply filters and sorting
  void _applyFiltersAndSort() {
    setState(() {
      List<Provider> tempProviders = List.from(_providers);
      
      // Apply radius filter if a position is available
      if(_currentPosition != null) {
         tempProviders = tempProviders.where((p) => (p.distance * 1000) <= _selectedRadius).toList();
      }

      // Apply availability filter
      if (_showAvailableOnly) {
         tempProviders = tempProviders.where((p) => p.isAvailable).toList();
      }
      
      // Apply sorting
      switch (_sortBy) {
        case 'distance':
          tempProviders.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case 'rating':
          tempProviders.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'availability':
          tempProviders.sort((a, b) {
            if (a.isAvailable == b.isAvailable) return 0;
            return a.isAvailable ? -1 : 1;
          });
          break;
      }
      _filteredProviders = tempProviders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: _getServiceColor(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _openMapView,
            tooltip: 'Map View',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterDialog,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and sort info bar
          _buildInfoBar(),
          
          // Providers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProviders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProviders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProviders.length,
                          itemBuilder: (context, index) {
                            final provider = _filteredProviders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProviderCard(
                                provider: provider,
                                onTap: () => _navigateToProviderDetails(provider),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _filteredProviders.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openMapView,
              backgroundColor: _getServiceColor(),
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text(
                'Map View',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  // Build information bar showing current filters
  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _getServiceColor().withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_filteredProviders.length} ${_filteredProviders.length == 1 ? 'provider' : 'providers'} found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _getServiceColor(),
              ),
            ),
          ),
          if (_showAvailableOnly)
            Chip(
              label: const Text(
                'Available Only',
                style: TextStyle(fontSize: 10),
              ),
              backgroundColor: Colors.green.withOpacity(0.2),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() {
                  _showAvailableOnly = false;
                });
                _applyFiltersAndSort();
              },
            ),
            // Add this snippet
          if (_selectedRadius < 50000) // Only show chip if a filter is active
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Chip(
                label: Text(
                  'Within ${_selectedRadius ~/ 1000} km',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.blue.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedRadius = 50000; // Reset to default "All"
                  });
                  _applyFiltersAndSort();
                },
              ),
            ),
          const SizedBox(width: 8),
          Text(
            'Sort: ${_sortBy.toUpperCase()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
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
              _getServiceIcon(),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No providers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or increasing the radius.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProviders,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // Show filter and sort dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Sort'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Availability filter
                    const Text('Filter by Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text('Show available only'),
                      subtitle: const Text('Hide busy providers'),
                      value: _showAvailableOnly,
                      onChanged: (value) {
                        setDialogState(() {
                          _showAvailableOnly = value ?? false;
                        });
                      },
                    ),
                    const Divider(),
                    // Radius filter
                    const Text('Filter by Distance', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                     Wrap(
                        spacing: 8.0,
                        children: [5000, 10000, 25000, 50000].map((radius) {
                          return ChoiceChip(
                            label: Text(radius >= 50000 ? 'All' : '${radius ~/ 1000} km'),
                            selected: _selectedRadius == radius.toDouble(),
                            onSelected: (selected) {
                               setDialogState(() {
                                _selectedRadius = radius.toDouble();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const Divider(),
                    // Sort options
                    const Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...['distance', 'rating', 'availability'].map((option) {
                      return RadioListTile<String>(
                        title: Text(_getSortTitle(option)),
                        value: option,
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setDialogState(() {
                            _sortBy = value ?? 'distance';
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFiltersAndSort();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // Navigate to provider details
  void _navigateToProviderDetails(Provider provider) {
    Navigator.pushNamed(
      context,
      '/provider-details',
      arguments: provider,
    );
  }

  // Open map view with current providers
  void _openMapView() {
    Navigator.pushNamed(
      context,
      '/map',
      arguments: {
        'providers': _filteredProviders,
        'serviceType': _serviceType,
      },
    );
  }

  // Get screen title based on service type
  String _getScreenTitle() {
    switch (_serviceType.toLowerCase()) {
      case 'hospital':
        return 'Hospitals';
      case 'police':
        return 'Police Stations';
      case 'ambulance':
        return 'Ambulance Services';
      default:
        return 'Emergency Services';
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

  // Get service-specific icon
  IconData _getServiceIcon() {
    switch (_serviceType.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'ambulance':
        return Icons.emergency;
      default:
        return Icons.emergency_share;
    }
  }

  // Get sort title for display
  String _getSortTitle(String sortBy) {
    switch (sortBy) {
      case 'distance':
        return 'Distance';
      case 'rating':
        return 'Rating';
      case 'availability':
        return 'Availability';
      default:
        return sortBy;
    }
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _initializeAndLoadProviders,
        ),
      ),
    );
  }
}