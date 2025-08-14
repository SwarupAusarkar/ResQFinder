import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../data/data_service.dart';
import '../widgets/provider_card.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProviders();
  }

  // Load providers based on service type from navigation arguments
  Future<void> _loadProviders() async {
    try {
      // Get service type from navigation arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _serviceType = args?['serviceType'] ?? 'hospital';
      
      // Load providers for the selected service type
      final providers = await DataService.getProvidersByType(_serviceType);
      
      if (mounted) {
        setState(() {
          _providers = providers;
          _filteredProviders = providers;
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
      // Apply availability filter
      _filteredProviders = _showAvailableOnly
          ? _providers.where((p) => p.isAvailable).toList()
          : List.from(_providers);
      
      // Apply sorting
      switch (_sortBy) {
        case 'distance':
          _filteredProviders.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case 'rating':
          _filteredProviders.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'availability':
          _filteredProviders.sort((a, b) {
            if (a.isAvailable == b.isAvailable) return 0;
            return a.isAvailable ? -1 : 1;
          });
          break;
      }
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
              _showAvailableOnly 
                  ? 'No available providers found'
                  : 'No providers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showAvailableOnly
                  ? 'Try removing the availability filter'
                  : 'No ${_serviceType} providers in your area',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            if (_showAvailableOnly)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAvailableOnly = false;
                  });
                  _applyFiltersAndSort();
                },
                child: const Text('Show All Providers'),
              )
            else
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
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Availability filter
            const Text(
              'Filter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Show available only'),
              subtitle: const Text('Hide busy providers'),
              value: _showAvailableOnly,
              onChanged: (value) {
                setState(() {
                  _showAvailableOnly = value ?? false;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Sort options
            const Text(
              'Sort by',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...['distance', 'rating', 'availability'].map((option) {
              return RadioListTile<String>(
                title: Text(_getSortTitle(option)),
                subtitle: Text(_getSortSubtitle(option)),
                value: option,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value ?? 'distance';
                  });
                },
              );
            }),
          ],
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
      ),
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

  // Get sort subtitle for display
  String _getSortSubtitle(String sortBy) {
    switch (sortBy) {
      case 'distance':
        return 'Closest first';
      case 'rating':
        return 'Highest rated first';
      case 'availability':
        return 'Available first';
      default:
        return '';
    }
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
          onPressed: _loadProviders,
        ),
      ),
    );
  }
}