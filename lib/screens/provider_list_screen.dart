import 'package:emergency_res_loc_new/screens/OfferApprovalScreen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
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

    if (query.isNotEmpty) {
      setState(() {
        _searchSuggestions = _commonServices
            .where((service) =>
            service.toLowerCase().contains(query.toLowerCase()))
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
      setState(() {
        _filteredProviders = List.from(_allProviders);
      });
      _applyFiltersAndSort();
      return;
    }

    try {
      setState(() => _isLoading = true);

      final lowerQuery = query.toLowerCase();

      // Search by provider name AND inventory items
      List<Provider> searchResults = _allProviders.where((provider) {
        final nameMatch = provider.name.toLowerCase().contains(lowerQuery);
        final inventoryMatch = provider.inventory.any(
              (item) => item.name.toLowerCase().contains(lowerQuery),
        );
        return nameMatch || inventoryMatch;
      }).toList();

      // If local search yields no results, try live service
      if (searchResults.isEmpty) {
        try {
          searchResults = await LiveDataService.searchProvidersByService(
            service: query,
            latitude: _currentPosition?.latitude ?? 19.0760,
            longitude: _currentPosition?.longitude ?? 72.8777,
          );

          // Calculate distances for live results
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
        } catch (e) {
          debugPrint("Live search failed: $e");
        }
      }

      if (mounted) {
        setState(() {
          _filteredProviders = searchResults;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      _filteredProviders = List.from(_allProviders);
    });
    _applyFiltersAndSort();
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
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Could not get current location.');
    }
  }

  Future<void> _loadProviders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _serviceType = args?['serviceType'] ?? 'hospital';

      List<Provider> providers;
      try {
        providers = await LiveDataService.fetchProviders(
          serviceType: _serviceType,
          latitude: _currentPosition?.latitude ?? 19.0760,
          longitude: _currentPosition?.longitude ?? 72.8777,
        );
      } catch (e) {
        debugPrint("Live data failed, falling back to static: $e");
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
          return provider.copyWith(distance: distanceInMeters / 1000);
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

  void _applyFiltersAndSort() {
    setState(() {
      List<Provider> tempProviders = _isSearching
          ? List.from(_filteredProviders)
          : List.from(_allProviders);

      if (_currentPosition != null) {
        tempProviders = tempProviders
            .where((p) => (p.distance * 1000) <= _selectedRadius)
            .toList();
      }

      if (_showAvailableOnly) {
        tempProviders = tempProviders.where((p) => p.isAvailable).toList();
      }

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
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: (){Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApprovalScreen()
              ),
            );
            },
            tooltip: 'Filter & Sort',
          ),

        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showSuggestions) _buildSearchSuggestions(),
          _buildInfoBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProviders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _isSearching
                  ? () => _performSearch(_currentSearchQuery)
                  : _loadProviders,
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
                      searchQuery: _currentSearchQuery,
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
        onPressed:() {
      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendRequestScreen(
          inventoryItem: InventoryItem(
            name: 'Select Item',
            quantity: 0,
            unit: 'Units',
            lastUpdated: DateTime.now(),
          ),
        ),
      ),
    );
  },
        backgroundColor: _getServiceColor(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New  Request',
          style: TextStyle(color: Colors.white),
        ),
      )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
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
                hintText: 'Search services or providers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (_isSearching) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getServiceColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getServiceColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 14,
                    color: _getServiceColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
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
            leading: Icon(
              Icons.medical_services,
              size: 18,
              color: Colors.grey[600],
            ),
            title: Text(suggestion),
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }

 Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: _getServiceColor().withOpacity(0.1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              '${_filteredProviders.length} ${_filteredProviders.length == 1 ? 'provider' : 'providers'}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _getServiceColor(),
                fontSize: 13,
              ),
            ),
            if (_isSearching) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  '"$_currentSearchQuery"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(width: 12),
            if (_showAvailableOnly)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  label: const Text(
                    'Available',
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.2),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _showAvailableOnly = false);
                    _applyFiltersAndSort();
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            if (_selectedRadius < 50000)
              Chip(
                label: Text(
                  '${_selectedRadius ~/ 1000}km',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.blue.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  setState(() => _selectedRadius = 50000);
                  _applyFiltersAndSort();
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: 8),
            Text(
              'Sort: ${_getSortTitle(_sortBy)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  ? 'Try a different search term or clear the search.'
                  : 'Try adjusting your filters or increasing the radius.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
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
                    const Text(
                      'Filter by Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                    const Text(
                      'Filter by Distance',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: [5000, 10000, 25000, 50000].map((radius) {
                        return ChoiceChip(
                          label: Text(
                            radius >= 50000 ? 'All' : '${radius ~/ 1000} km',
                          ),
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
                    const Text(
                      'Sort by',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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

  void _navigateToProviderDetails(Provider provider) {
    Navigator.pushNamed(context, '/provider-details', arguments: provider);
  }

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

  void _showErrorSnackBar(String message) {
    if (!mounted)
    return;
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