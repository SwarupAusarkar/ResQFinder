// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../models/request_model.dart';
// import '../../services/auth_service.dart';
// import 'package:intl/intl.dart';
//
// class HistoryPage extends StatefulWidget {
//   const HistoryPage({super.key});
//
//   @override
//   State<HistoryPage> createState() => _HistoryPageState();
// }
//
// class _HistoryPageState extends State<HistoryPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthService _authService = AuthService();
//
//   @override
//   Widget build(BuildContext context) {
//     final userId = _authService.currentUser?.uid;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('History'),
//         backgroundColor: const Color(0xFF0D4F4A),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('emergency_requests')
//             .where('status', isEqualTo: 'completed')
//             .orderBy('completedAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 "Error loading history: ${snapshot.error}",
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
//               .where((req) =>
//           req.offers.any((o) => o.providerId == userId) &&
//               req.status == 'completed')
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
//               final wasWinner = req.confirmedProviderId == userId;
//               return _buildHistoryCard(req, wasWinner);
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildHistoryCard(EmergencyRequest request, bool wasWinner) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: wasWinner
//             ? Border.all(color: Colors.green[300]!, width: 2)
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
//           // Status Header
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//             decoration: BoxDecoration(
//               color: wasWinner ? Colors.green[50] : Colors.blue[50],
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(16),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   wasWinner ? Icons.check_circle : Icons.history,
//                   color: wasWinner ? Colors.green[700] : Colors.blue[700],
//                   size: 18,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   wasWinner ? 'COMPLETED' : 'PARTICIPATED',
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                     color: wasWinner ? Colors.green[900] : Colors.blue[900],
//                     letterSpacing: 1,
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   _formatDate(request.timestamp),
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Request Details
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: wasWinner
//                             ? Colors.green[100]
//                             : Colors.blue[100],
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Icon(
//                         Icons.medical_services_rounded,
//                         color: wasWinner
//                             ? Colors.green[700]
//                             : Colors.blue[700],
//                         size: 20,
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
//                               fontSize: 15,
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
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(Icons.location_on_outlined,
//                                   size: 14, color: Colors.grey[600]),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   request.locationName,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 // Earnings (if winner)
//                 if (wasWinner) ...[
//                   const SizedBox(height: 16),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.green[50],
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: Colors.green[200]!),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.monetization_on,
//                             color: Colors.green[700], size: 20),
//                         const SizedBox(width: 8),
//                         const Expanded(
//                           child: Text(
//                             "Service completed successfully",
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                         Icon(Icons.verified,
//                             color: Colors.green[700], size: 18),
//                       ],
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
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
//             Icon(Icons.history_outlined, size: 80, color: Colors.grey[300]),
//             const SizedBox(height: 20),
//             Text(
//               'No History Yet',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Your completed requests will appear here',
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
//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final dateOnly = DateTime(date.year, date.month, date.day);
//
//     if (dateOnly == today) {
//       return 'Today, ${DateFormat('h:mm a').format(date)}';
//     } else if (dateOnly == yesterday) {
//       return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
//     } else {
//       return DateFormat('MMM d, h:mm a').format(date);
//     }
//   } }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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
                        Icons.history_rounded,
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
                          'History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Your past completed requests',
                          style: TextStyle(
                              fontSize: 11, color: Colors.white60),
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
              .where('status', isEqualTo: 'completed')
              .orderBy('completedAt', descending: true)
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
            req.offers.any((o) => o.providerId == userId) &&
                req.status == 'completed')
                .toList();

            if (requests.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                final wasWinner = req.confirmedProviderId == userId;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(
                      milliseconds: 300 + (index * 60).clamp(0, 600)),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                        offset: Offset(0, 20 * (1 - v)), child: child),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildHistoryCard(req, wasWinner),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryCard(EmergencyRequest request, bool wasWinner) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: wasWinner
            ? Border.all(
            color: const Color(0xFF43A047).withOpacity(0.6),
            width: 1.5)
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
          // ── Status Header ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: wasWinner
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFE3F2FD),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: wasWinner
                        ? const Color(0xFF43A047).withOpacity(0.15)
                        : const Color(0xFF1565C0).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    wasWinner
                        ? Icons.check_circle_rounded
                        : Icons.history_rounded,
                    color: wasWinner
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF1565C0),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  wasWinner ? 'COMPLETED' : 'PARTICIPATED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: wasWinner
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF0D47A1),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: wasWinner
                            ? const Color(0xFF43A047).withOpacity(0.1)
                            : const Color(0xFF1565C0).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.medical_services_rounded,
                        color: wasWinner
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1565C0),
                        size: 20,
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
                          const SizedBox(height: 4),
                          Text(
                            request.requesterName ?? "Emergency Request",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 13, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.locationName,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Completion badge (winner only) ─────────────────
                if (wasWinner) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Service completed successfully',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
            Text('Could not load history',
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
                color: const Color(0xFF00897B).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 52,
                color: Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nothing Here Yet',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed requests will appear here\nonce you start fulfilling them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }
}