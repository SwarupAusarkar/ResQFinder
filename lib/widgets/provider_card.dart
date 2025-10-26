// lib/widgets/provider_card.dart

import 'package:flutter/material.dart';
import '../models/provider_model.dart';

// Reusable widget for displaying provider information in a card
class ProviderCard extends StatelessWidget {
  final Provider provider;
  final VoidCallback? onTap;
  final String? searchQuery; // NEW: For highlighting search results

  const ProviderCard({
    super.key,
    required this.provider,
    this.onTap,
    this.searchQuery, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and availability
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getServiceColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.iconPath,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Provider name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                provider.address,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Availability status
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // ** START: MODIFICATION **
              // NEW: Services offered (with search highlighting)
              if (provider.inventory.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildServicesSection(),
              ],
              // ** END: MODIFICATION **
              
              const SizedBox(height: 12),
              
              // Provider details row
              Row(
                children: [
                  // Distance
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.near_me,
                      label: '${provider.distance.toStringAsFixed(1)} km',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Rating
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.star,
                      label: '${provider.rating}/5',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Phone call button
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.phone,
                      label: 'Call',
                      color: Colors.green,
                      onTap: () => _showPhoneDialog(context),
                    ),
                  ),
                ],
              ),
              
              // Description (if provided)
              if (provider.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  provider.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ** START: MODIFICATION **
  // NEW: Build services section with search highlighting
  Widget _buildServicesSection() {
    final displayItems = provider.inventory.take(3).toList();
    final hasMore = provider.inventory.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ...displayItems.map((item) => _buildServiceChip(item.name)),
            if (hasMore)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${provider.inventory.length - 3} more',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  // ** END: MODIFICATION **

  // NEW: Build individual service chip with highlighting
  Widget _buildServiceChip(String service) {
    final isHighlighted = searchQuery != null && 
        searchQuery!.isNotEmpty && 
        service.toLowerCase().contains(searchQuery!.toLowerCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? Colors.amber.withOpacity(0.3)
            : _getServiceColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted 
            ? Border.all(color: Colors.amber, width: 1)
            : Border.all(color: _getServiceColor().withOpacity(0.3), width: 1),
      ),
      child: Text(
        service,
        style: TextStyle(
          fontSize: 10,
          color: isHighlighted 
              ? Colors.orange[800]
              : _getServiceColor(),
          fontWeight: isHighlighted 
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    );
  }

  // Build info chip widget
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Build action button widget
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
  }

  // Get service type color
  Color _getServiceColor() {
    switch (provider.type.toLowerCase()) {
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

  // Show phone call dialog
  void _showPhoneDialog(BuildContext context) {
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
                SnackBar(
                  content: Text('Calling ${provider.name}...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }
}