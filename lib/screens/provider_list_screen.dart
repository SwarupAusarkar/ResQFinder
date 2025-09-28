import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/provider_model.dart';
import '../data/data_service.dart';
import '../widgets/provider_card.dart';
import '../data/live_data_service.dart';

// Screen showing list of providers with live inventory search
class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  List<Provider> _allProviders = [];
  List<Provider> _filteredProviders = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _serviceType = '';
  String _sortBy = 'distance'; // distance, rating, availability
  bool _showAvailableOnly = false;
  Position? _currentPosition;
  double _selectedRadius = 50000; // Default to 50km to show all initially
  
  // Search related
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';
  Timer? _searchDebouncer;
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  // Common emergency services for suggestions
  final List<String> _commonServices = [
    'ICU Bed',
    'Emergency Surgery',
    'Ambulance',
    'Blood Bank',
    'X-Ray',
    'MRI Scan',
    'CT Scan',
    'Dialysis',
    'Oxygen Cylinder',
    'Ventilator',
    'Emergency Medicine',
    'Pediatric Care',
    'Cardiology',
    'Neurology',
    'Orthopedic',
    '24/7 Pharmacy',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    // Use a post-frame callback to safely access ModalRoute
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

  void _onSearchTextChanged() {
    final query = _searchController.text;
    
    // Update suggestions
    if (query.isNotEmpty) {
      setState(() {
        _searchSuggestions = _commonServices
            .where((service) => service.toLowerCase().contains(query.toLowerCase()))
            .take(5)
            .toList();
        _showSuggestions = true;
      });
    } else {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
      });
    }

    // Debounce the search
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    
    setState(() {
      _currentSearchQuery = query;
      _isSearching = query.isNotEmpty;
      _showSuggestions = false;
    });

    if (query.isEmpty) {
      // If search is cleared, show all providers with current filters
      _applyFiltersAndSort();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      List<Provider> searchResults;
      
      // Try live service first, fallback to static data
      try {
        searchResults = await LiveDataService.searchProvidersByService(
          service: query,
          latitude: _currentPosition?.latitude ?? 19.0760,
          longitude: _currentPosition?.longitude ?? 72.8777,
        );
      } catch (e) {
        debugPrint("⚠️ Live search failed, searching static data: $e");
        searchResults = await DataService.searchProvidersByService(query);
      }

      // Calculate distances if position is available
      if (_currentPosition != null) {
        searchResults = searchResults.map((provider) {
          final distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            provider.latitude,
            provider.longitude,
          );
          return provider.copyWith(distance: distanceInMeters / 1000);
        }).toList();
      }

      if (mounted) {
        setState(() {
          _allProviders = searchResults;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Search failed: $e');
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    _performSearch(suggestion);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearchQuery = '';
      _isSearching = false;
      _showSuggestions = false;
    });
    _loadProviders(); // Reload original providers
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
          _allProviders = providers;
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
      List<Provider> tempProviders = List.from(_allProviders);
      
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
        title: Text(_isSearching ? 'Search Results' : _getScreenTitle()),
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
          // Search bar
          _buildSearchBar(),
          
          // Search suggestions
          if (_showSuggestions) _buildSearchSuggestions(),
          
          // Filter and sort info bar
          _buildInfoBar(),
          
          // Providers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProviders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _isSearching ? () => _performSearch(_currentSearchQuery) : _loadProviders,
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
                                searchQuery: _currentSearchQuery, // Pass search query for highlighting
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

  // Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for services (e.g., ICU Bed, Ambulance)',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          if (_isSearching) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getServiceColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getServiceColor().withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: _getServiceColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getServiceColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build search suggestions dropdown
  Widget _buildSearchSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _searchSuggestions[index];
          return ListTile(
            dense: true,
            leading: Icon(Icons.medical_services, 
                        size: 18, 
                        color: Colors.grey[600]),
            title: Text(suggestion),
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_filteredProviders.length} ${_filteredProviders.length == 1 ? 'provider' : 'providers'} found',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getServiceColor(),
                  ),
                ),
                if (_isSearching)
                  Text(
                    'Searching for: "$_currentSearchQuery"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
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
          if (_selectedRadius < 50000)
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
                    _selectedRadius = 50000;
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
              _isSearching ? Icons.search_off : _getServiceIcon(),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching 
                  ? 'No providers found for "$_currentSearchQuery"'
                  : 'No providers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Try a different search term or clear the search to see all providers.'
                  : 'Try adjusting your filters or increasing the radius.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            if (_isSearching) ...[
              ElevatedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _isSearching 
                  ? () => _performSearch(_currentSearchQuery)
                  : _loadProviders,
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
        'searchQuery': _currentSearchQuery,
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