import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../data/data_service.dart';

class ProvidersListScreen extends StatefulWidget {
  final String serviceType; // hospital, police, ambulance

  const ProvidersListScreen({super.key, required this.serviceType});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen> {
  late Future<List<Provider>> _futureProviders;

  @override
  void initState() {
    super.initState();
    _futureProviders = DataService.getAvailableProviders(widget.serviceType);
  }

  String _getServiceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return '🏥';
      case 'police':
        return '🚓';
      case 'ambulance':
        return '🚑';
      default:
        return '📞';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.serviceType} Providers'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Provider>>(
        future: _futureProviders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '❌ Failed to load providers.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No providers found.'));
          }

          final providers = snapshot.data!;

          return ListView.separated(
            itemCount: providers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return ListTile(
                leading: Text(
                  _getServiceIcon(provider.type),
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(provider.name),
                subtitle: Text(
                  '${provider.address}\n${provider.distance.toStringAsFixed(1)} km away',
                ),
                isThreeLine: true,
                trailing: Icon(
                  provider.isAvailable
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: provider.isAvailable ? Colors.green : Colors.red,
                ),
                onTap: () {
                  // You can navigate to details screen here
                },
              );
            },
          );
        },
      ),
    );
  }
}