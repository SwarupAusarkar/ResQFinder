// import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:uuid/uuid.dart';
// import '../services/auth_service.dart';
// import '../services/location_service.dart';
//
// class SendRequestScreen extends StatefulWidget {
//   const SendRequestScreen({super.key, required InventoryItem inventoryItem});
//
//   @override
//   State<SendRequestScreen> createState() => _SendRequestScreenState();
// }
//
// class _SendRequestScreenState extends State<SendRequestScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _quantityController = TextEditingController();
//   final _descriptionController = TextEditingController();
//
//   String? _selectedItem;
//   String? _selectedUnit = 'Units';
//   double _searchRadius = 1.5; // Changed to 1.5km as requested
//   bool _isSending = false;
//   double lat = 0.0, long = 0.0;
//
//   final List<String> _inventoryItems = [
//     'ICU Bed',
//     'Emergency Surgery',
//     'Ambulance',
//     'Blood Bank',
//     'X-Ray',
//     'MRI Scan',
//     'CT Scan',
//     'Dialysis',
//     'Oxygen Cylinder',
//     'Ventilator',
//     'Emergency Medicine',
//     'Pediatric Care',
//     'Cardiology',
//     'Neurology',
//     'Orthopedic',
//     '24/7 Pharmacy',
//   ];
//   final List<String> _units = ['Units', 'Liters', 'Beds', 'Packets'];
//
//   Future<void> _sendBroadcastRequest() async {
//     if (!_formKey.currentState!.validate() || _selectedItem == null) return;
//
//     setState(() => _isSending = true);
//
//     try {
//       final user = AuthService().currentUser;
//       final userDoc =
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(user!.uid)
//               .get();
//       final userData = userDoc.data()!;
//
//       double userLat = lat;
//       double userLon = long;
//       print(userLat);print(userLon);
//       // FIXED: Changed status to 'pending' to match provider dashboard expectations
//       await FirebaseFirestore.instance.collection('emergency_requests').add({
//         'masterRequestId': const Uuid().v4(),
//         'requesterId': user.uid,
//         'requesterName': userData['fullName'] ?? 'Anonymous',
//         'requesterPhone': userData['phone'] ?? 'N/A',
//         'latitude': userLat,
//         'longitude': userLon,
//         'location': GeoPoint(userLat, userLon),
//         'itemName': _selectedItem,
//         'itemQuantity': int.parse(_quantityController.text),
//         'itemUnit': _selectedUnit,
//         'description': _descriptionController.text.trim(),
//         'status': 'pending', // Changed from 'open' to 'pending'
//         'timestamp': FieldValue.serverTimestamp(),
//         'radius': _searchRadius,
//       });
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Emergency request broadcasted to nearby providers!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       _showSnackBar("Error: $e", Colors.red);
//     } finally {
//       if (mounted) setState(() => _isSending = false);
//     }
//   }
//
//   void _showSnackBar(String msg, Color color) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     LocationService.getCurrentLocation().then((pos) {
//       if (pos != null) {
//         lat = pos.latitude;
//         long = pos.longitude;
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('New Emergency Request'),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Select Resource Needed",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               DropdownButtonFormField<String>(
//                 value: _selectedItem,
//                 items:
//                     _inventoryItems
//                         .map(
//                           (item) =>
//                               DropdownMenuItem(value: item, child: Text(item)),
//                         )
//                         .toList(),
//                 onChanged: (val) => setState(() => _selectedItem = val),
//                 decoration: _inputStyle("Resource Type"),
//                 validator: (v) => v == null ? "Please select a resource" : null,
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: TextFormField(
//                       controller: _quantityController,
//                       keyboardType: TextInputType.number,
//                       decoration: _inputStyle("Quantity"),
//                       validator:
//                           (v) => (v == null || v.isEmpty) ? "Required" : null,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     flex: 1,
//                     child: DropdownButtonFormField<String>(
//                       value: _selectedUnit,
//                       items:
//                           _units
//                               .map(
//                                 (u) =>
//                                     DropdownMenuItem(value: u, child: Text(u)),
//                               )
//                               .toList(),
//                       onChanged: (val) => setState(() => _selectedUnit = val),
//                       decoration: _inputStyle("Unit"),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Search Radius (Broadcast Range)",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               Slider(
//                 value: _searchRadius,
//                 min: 0.5,
//                 max: 5.0,
//                 divisions: 9,
//                 label: "${_searchRadius.toStringAsFixed(1)} km",
//                 activeColor: Colors.redAccent,
//                 onChanged: (v) => setState(() => _searchRadius = v),
//               ),
//               Text(
//                 "Your request will be sent to all providers within ${_searchRadius.toStringAsFixed(1)} km",
//                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 10),
//               TextFormField(
//                 controller: _descriptionController,
//                 maxLines: 3,
//                 decoration: _inputStyle(
//                   "Emergency Details (e.g. Patient condition)",
//                 ),
//                 validator:
//                     (v) =>
//                         (v == null || v.isEmpty)
//                             ? "Please describe the situation"
//                             : null,
//               ),
//               const SizedBox(height: 30),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isSending ? null : _sendBroadcastRequest,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.redAccent,
//                     padding: const EdgeInsets.symmetric(vertical: 18),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child:
//                       _isSending
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text(
//                             "BROADCAST REQUEST",
//                             style: TextStyle(fontSize: 18, color: Colors.white),
//                           ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _requestLocationPermission() async {
//     try {
//       bool serviceEnabled;
//       LocationPermission permission;
//
//       serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         print('⚠️ Location services are disabled.');
//         return;
//       }
//
//       permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           print('⚠️ Location permissions are denied');
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         print('⚠️ Location permissions are permanently denied');
//         return;
//       }
//
//       print("✓ Location permissions granted");
//     } catch (e) {
//       print("⚠️ Location permission error: $e");
//     }
//   }
//
//   InputDecoration _inputStyle(String label) {
//     return InputDecoration(
//       labelText: label,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       filled: true,
//       fillColor: Colors.grey[100],
//     );
//   }
// }
//
import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import '../data/master_inventory_list.dart'; // Ensure this contains the masterInventory list
import '../services/auth_service.dart';
import '../services/location_service.dart';

class SendRequestScreen extends StatefulWidget {
  const SendRequestScreen({super.key, required InventoryItem inventoryItem});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedItem;
  String? _selectedUnit;
  double _searchRadius = 1.5;
  bool _isSending = false;
  double lat = 0.0, long = 0.0;
  String loc="";
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Attempt to get location immediately
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        lat = pos.latitude;
        long = pos.longitude;
      });  print(lat);print(long);
      loc = await LocationService.getAddressFromLatLng(lat, long); print(loc);
    }
  }

  void _onResourceChanged(String? newValue) {
    if (newValue == null) return;

    // ✅ Fix: Use the masterInventory list directly
    final foundItem = masterInventoryList.firstWhere(
      (item) => item.name == newValue,
      orElse: () => const MasterInventoryItem(name: '', unit: 'Units'),
    );

    setState(() {
      _selectedItem = newValue;
      _selectedUnit = foundItem.unit;
    });
  }

  Future<void> _sendBroadcastRequest() async {
    // 1. Basic Validation
    if (!_formKey.currentState!.validate() || _selectedItem == null) return;

    // 2. Safety Check: Location check
    if (lat == 0.0) {
      // Try one last time to get location before failing
      await _initLocation();
      if (lat == 0.0) {
        _showSnackBar(
          "Getting location... please ensure GPS is on.",
          Colors.orange,
        );
        return;
      }
    }

    setState(() => _isSending = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception("User session expired.");

      // Fetch requester profile for the latest contact info
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data() ?? {};

      // 3. Create the Handshake/Broadcast document
      await FirebaseFirestore.instance.collection('emergency_requests').add({
        'masterRequestId': const Uuid().v4(),
        'requesterId': user.uid,
        'requesterName': userData['name'] ?? 'Anonymous',
        'requesterPhone': userData['phone'] ?? 'N/A',
        'latitude': lat,
        'longitude': long,
        'locationName': loc,
        'itemName': _selectedItem,
        'itemQuantity': int.parse(_quantityController.text),
        'itemUnit': _selectedUnit,
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'radius': _searchRadius,
        'declinedBy': [], // For personal provider-side filtering
        'acceptedAt': null, // Placeholder for the 5-min timer logic
        'verificationCode': null, // Placeholder for the Zomato-style OTP
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Emergency broadcast active! Nearby providers notified.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Broadcast Failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Emergency Request'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("What resource is needed?"),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedItem,
                // ✅ Fix: Map from the masterInventory list
                items:
                    masterInventoryList
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.name,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                onChanged: _onResourceChanged,
                decoration: _inputDecoration("Select Resource Type"),
                validator: (v) => v == null ? "Please select an item" : null,
              ),

              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Quantity"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration("Number"),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            if (int.tryParse(v) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Unit"),
                        const SizedBox(height: 8),
                        _buildReadOnlyField(_selectedUnit ?? "---"),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(
                "Search Radius: ${_searchRadius.toStringAsFixed(1)} km",
              ),
              Slider(
                value: _searchRadius,
                min: 0.5,
                max: 10.0,
                divisions: 19,
                label: "${_searchRadius.toStringAsFixed(1)} km",
                activeColor: Colors.redAccent,
                onChanged: (v) => setState(() => _searchRadius = v),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Emergency Details"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  "e.g. Critical condition, blood group, etc.",
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? "Description is helpful for providers"
                            : null,
              ),

              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Colors.black54,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget _buildReadOnlyField(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendBroadcastRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSending
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  "SEND REQUEST",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
