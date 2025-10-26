// lib/screens/send_request_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/provider_model.dart';
import '../models/inventory_item_model.dart';
import '../services/auth_service.dart';

class SendRequestScreen extends StatefulWidget {
  final Provider provider;
  final InventoryItem inventoryItem;

  const SendRequestScreen({
    super.key,
    required this.provider,
    required this.inventoryItem,
  });

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send a request.')),
      );
      setState(() => _isSending = false);
      return;
    }

    final masterRequestId = const Uuid().v4();
    final requestedQuantity = int.tryParse(_quantityController.text) ?? 0;

    final requestData = {
      'masterRequestId': masterRequestId,
      'requesterId': user.uid,
      'requesterName': user.displayName ?? user.email,
      'providerId': widget.provider.id,
      'providerName': widget.provider.name,
      'requestedItem': {
        'name': widget.inventoryItem.name,
        'quantity': requestedQuantity,
        'unit': widget.inventoryItem.unit,
      },
      'description': _descriptionController.text.trim(),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('emergency_requests').add(requestData);

      if (mounted) {
        Navigator.pop(context); // Go back to the details screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Item'),
        backgroundColor: _getServiceColor(widget.provider.type),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Item: ${widget.inventoryItem.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('From: ${widget.provider.name}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Available: ${widget.inventoryItem.quantity} ${widget.inventoryItem.unit}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity Needed',
                  hintText: 'e.g., 2',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid quantity.';
                  }
                  if (quantity > widget.inventoryItem.quantity) {
                    return 'Quantity cannot exceed available stock.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Brief Description of Emergency',
                  hintText: 'e.g., Road accident victim',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a brief description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSending ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getServiceColor(widget.provider.type),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Request', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getServiceColor(String type) {
    switch (type.toLowerCase()) {
      case 'hospital': return Colors.red;
      case 'police': return Colors.blue;
      case 'ambulance': return Colors.orange;
      default: return Colors.blue;
    }
  }
}