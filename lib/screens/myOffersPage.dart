// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart';
// import '../../models/request_model.dart';
// import '../../services/auth_service.dart';
// import '../../services/HandShakeService.dart';
// import 'package:intl/intl.dart';
//
// class MyOffersPage extends StatefulWidget {
//   const MyOffersPage({super.key});
//
//   @override
//   State<MyOffersPage> createState() => _MyOffersPageState();
// }
//
// class _MyOffersPageState extends State<MyOffersPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthService _authService = AuthService();
//
//   @override
//   Widget build(BuildContext context) {
//     final userId = _authService.currentUser?.uid;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Offers'),
//         backgroundColor: const Color(0xFF0D4F4A),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('emergency_requests')
//             .where('status', whereIn: ['pending', 'confirmed'])
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 "Error loading offers: ${snapshot.error}",
//                 style: TextStyle(color: Colors.red[300]),
//               ),
//             );
//           }
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation(Color(0xFF00897B)),
//               ),
//             );
//           }
//
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           var requests = snapshot.data!.docs
//               .map((doc) => EmergencyRequest.fromFirestore(doc))
//               .where((req) => req.offers.any((o) => o.providerId == userId))
//               .toList();
//
//           if (requests.isEmpty) {
//             return _buildEmptyState();
//           }
//
//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: requests.length,
//             itemBuilder: (context, index) {
//               final req = requests[index];
//               final isWinner = req.status == 'confirmed' &&
//                   req.confirmedProviderId == userId;
//
//               return _buildOfferCard(req, isWinner);
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildOfferCard(EmergencyRequest request, bool isWinner) {
//     final myOffer = request.offers
//         .firstWhere((o) => o.providerId == _authService.currentUser?.uid);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: isWinner
//             ? Border.all(color: const Color(0xFF00897B), width: 2)
//             : null,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Winner Banner
//           if (isWinner) _buildWinnerBanner(),
//
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Request Details
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF00897B).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.medical_services_rounded,
//                         color: Color(0xFF00897B),
//                         size: 24,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "${request.itemQuantity} ${request.itemUnit} ${request.itemName}",
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1A1A1A),
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             request.requesterName ?? "Emergency Request",
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     _buildStatusChip(request.status, isWinner),
//                   ],
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Destination Info
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blue[100]!),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.location_on, color: Colors.blue[700], size: 20),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "DESTINATION",
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue[900],
//                                 letterSpacing: 1,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               request.locationName,
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.blue[900],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       // Navigate Button
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           // TODO: Open maps
//                         },
//                         icon: const Icon(Icons.navigation, size: 16),
//                         label: const Text(
//                           'Navigate',
//                           style: TextStyle(fontSize: 12),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue[700],
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 8,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           elevation: 0,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Verification Section (if winner)
//                 if (isWinner && request.verificationCode != null) ...[
//                   const SizedBox(height: 16),
//                   _buildVerificationSection(request),
//                 ],
//
//                 // Time Info
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
//                     const SizedBox(width: 4),
//                     Text(
//                       "Sent ${_formatTime(myOffer.acceptedAt)}",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildWinnerBanner() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF00897B), Color(0xFF00695C)],
//         ),
//         borderRadius: const BorderRadius.vertical(
//           top: Radius.circular(16),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.celebration, color: Colors.white, size: 20),
//           const SizedBox(width: 8),
//           const Text(
//             "CONGRATULATIONS! YOU'RE SELECTED",
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 13,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVerificationSection(EmergencyRequest request) {
//     final codeController = TextEditingController();
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.green[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.green[200]!),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.security, color: Colors.green[700], size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 "Secure Handshake Verification",
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green[900],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             "Ask the requester for the verification code. Both parties must confirm this code to complete the handshake.",
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[700],
//               height: 1.4,
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // Code Input
//           Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: codeController,
//                   keyboardType: TextInputType.number,
//                   maxLength: 6,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 8,
//                   ),
//                   decoration: InputDecoration(
//                     hintText: '------',
//                     counterText: '',
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: Colors.grey[300]!),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(
//                         color: Color(0xFF00897B),
//                         width: 2,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               ElevatedButton(
//                 onPressed: () async {
//                   final code = codeController.text.trim();
//                   if (code.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Please enter verification code'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                     return;
//                   }
//
//                   final handshakeService = HandshakeService();
//                   final result = await handshakeService
//                       .verifyAndCompleteRequest(
//                     requestId: request.id,
//                     providerInputCode: code,
//                   );
//
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(result['message']),
//                         backgroundColor:
//                         result['success'] ? Colors.green : Colors.red,
//                       ),
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00897B),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 16,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: const Text(
//                   'VERIFY',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 12),
//
//           // Help Info
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.amber[50],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     "Encountering issues with verification?",
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.amber[900],
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     // TODO: Show help dialog
//                   },
//                   style: TextButton.styleFrom(
//                     padding: EdgeInsets.zero,
//                     minimumSize: const Size(60, 30),
//                   ),
//                   child: Text(
//                     'Get Help',
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.amber[900],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusChip(String status, bool isWinner) {
//     Color color;
//     String label;
//
//     if (isWinner) {
//       color = const Color(0xFF00897B);
//       label = 'ACCEPTED';
//     } else if (status == 'pending') {
//       color = Colors.orange;
//       label = 'WAITING';
//     } else {
//       color = Colors.grey;
//       label = status.toUpperCase();
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color, width: 1.5),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontSize: 10,
//           fontWeight: FontWeight.w800,
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.local_offer_outlined,
//                 size: 80, color: Colors.grey[300]),
//             const SizedBox(height: 20),
//             Text(
//               'No Active Offers',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Requests you offer for will appear here',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatTime(DateTime time) {
//     final now = DateTime.now();
//     final difference = now.difference(time);
//
//     if (difference.inMinutes < 1) return 'just now';
//     if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
//     if (difference.inHours < 24) return '${difference.inHours}h ago';
//     return DateFormat('MMM d, h:mm a').format(time);
//   } }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/HandShakeService.dart';
import 'package:intl/intl.dart';

class MyOffersPage extends StatefulWidget {
  const MyOffersPage({super.key});

  @override
  State<MyOffersPage> createState() => _MyOffersPageState();
}

class _MyOffersPageState extends State<MyOffersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: const Color(0xFF0A3D38),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00897B), Color(0xFF00897B)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'My Offers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Pending & confirmed offers',
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('emergency_requests')
              .where('status', whereIn: ['pending', 'confirmed'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF00897B)),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var requests = snapshot.data!.docs
                .map((doc) => EmergencyRequest.fromFirestore(doc))
                .where((req) =>
                req.offers.any((o) => o.providerId == userId))
                .toList();

            if (requests.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                final isWinner = req.status == 'confirmed' &&
                    req.confirmedProviderId == userId;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration:
                  Duration(milliseconds: 300 + (index * 60).clamp(0, 600)),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                        offset: Offset(0, 20 * (1 - v)), child: child),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildOfferCard(req, isWinner),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOfferCard(EmergencyRequest request, bool isWinner) {
    final myOffer = request.offers
        .firstWhere((o) => o.providerId == _authService.currentUser?.uid);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isWinner
            ? Border.all(color: const Color(0xFF00897B), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Winner Banner ─────────────────────────────────────────
          if (isWinner) _buildWinnerBanner(),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Item + Status row ───────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? const Color(0xFF00897B).withOpacity(0.1)
                            : const Color(0xFF00897B).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.medical_services_rounded,
                        color: isWinner
                            ? const Color(0xFF00897B)
                            : Color(0xFF00897B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${request.itemQuantity} ${request.itemUnit} ${request.itemName}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            request.requesterName ?? "Emergency Request",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(request.status, isWinner),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Destination row ─────────────────────────────────
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //       horizontal: 14, vertical: 12),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFFE3F2FD),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Row(
                //     children: [
                //       const Icon(Icons.location_on_rounded,
                //           color: Color(0xFF00897B), size: 18),
                //       const SizedBox(width: 8),
                //       Expanded(
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             const Text(
                //               'DESTINATION',
                //               style: TextStyle(
                //                 fontSize: 9,
                //                 fontWeight: FontWeight.w800,
                //                 color: Color(0xFF00897B),
                //                 letterSpacing: 1.2,
                //               ),
                //             ),
                //             const SizedBox(height: 2),
                //             Text(
                //               request.locationName,
                //               style: const TextStyle(
                //                 fontSize: 13,
                //                 fontWeight: FontWeight.w600,
                //                 color: Color(0xFF00897B),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //       ElevatedButton.icon(
                //         onPressed: () {
                //           // TODO: Open maps
                //         },
                //         icon: const Icon(Icons.navigation_rounded, size: 14),
                //         label: const Text('Navigate',
                //             style: TextStyle(fontSize: 12)),
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: const Color(0xFF00897B),
                //           foregroundColor: Colors.white,
                //           padding: const EdgeInsets.symmetric(
                //               horizontal: 12, vertical: 8),
                //           shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(10)),
                //           elevation: 0,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // ── Verification ────────────────────────────────────
                if (isWinner && request.verificationCode != null) ...[
                  const SizedBox(height: 16),
                  _buildVerificationSection(request),
                ],

                // ── Time sent ───────────────────────────────────────
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 5),
                    Text(
                      "Sent ${_formatTime(myOffer.acceptedAt)}",
                      style:
                      TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF00695C)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            "🎉  YOU'RE SELECTED!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection(EmergencyRequest request) {
    final codeController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Color(0xFF2E7D32), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Secure Handshake',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Ask the requester for the 6-digit verification code to confirm delivery.",
            style: TextStyle(
                fontSize: 12, color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    hintText: '······',
                    hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 20,
                        letterSpacing: 8),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF00897B), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  final code = codeController.text.trim();
                  if (code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                        const Text('Please enter verification code'),
                        backgroundColor: Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    return;
                  }
                  final result = await HandshakeService()
                      .verifyAndCompleteRequest(
                    requestId: request.id,
                    providerInputCode: code,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: result['success']
                            ? const Color(0xFF00897B)
                            : Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'VERIFY',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: Colors.amber[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Encountering issues with verification?",
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Show help dialog
                  },
                  child: Text(
                    'Get Help',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber[900],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isWinner) {
    Color color;
    String label;
    IconData icon;

    if (isWinner) {
      color = const Color(0xFF00897B);
      label = 'ACCEPTED';
      icon = Icons.check_circle_rounded;
    } else if (status == 'pending') {
      color = Colors.orange[700]!;
      label = 'WAITING';
      icon = Icons.hourglass_top_rounded;
    } else {
      color = Colors.grey[600]!;
      label = status.toUpperCase();
      icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red[200]),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3D38).withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 52,
                color: Color(0xFF0A3D38),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Offers',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Requests you offer for will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(time);
  }
}