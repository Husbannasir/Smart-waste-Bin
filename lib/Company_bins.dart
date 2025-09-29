// // lib/Company_bins.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class CompanyBinsScreen extends StatelessWidget {
//   const CompanyBinsScreen({super.key});

//   Future<String?> _getCompanyName() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return null;

//     final snap = await FirebaseFirestore.instance
//         .collection('companies')
//         .where('email', isEqualTo: user.email)
//         .limit(1)
//         .get();

//     if (snap.docs.isEmpty) return null;
//     final data = snap.docs.first.data() as Map<String, dynamic>;
//     return (data['name'] as String?)?.trim();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<String?>(
//       future: _getCompanyName(),
//       builder: (context, companySnapshot) {
//         if (companySnapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         final companyName = companySnapshot.data;
//         if (companyName == null || companyName.isEmpty) {
//           return const Scaffold(
//             body: Center(child: Text("No company found for this user")),
//           );
//         }

//         return Scaffold(
//           appBar: AppBar(
//             title: Text(
//               'My Bins ($companyName)',
//               style: const TextStyle(color: Colors.white),
//             ),
//             centerTitle: true,
//             backgroundColor: const Color(0xFF1EDE5E),
//           ),
//           // 🔹 Stream all bins, filter locally for OR: companyName | assignedCompanyName
//           body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//             stream: FirebaseFirestore.instance
//                 .collection('bins')
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final all = snapshot.data?.docs ?? const [];
//               final bins = all.where((d) {
//                 final m = d.data();
//                 final cn = (m['companyName'] as String?)?.trim() ?? '';
//                 final acn = (m['assignedCompanyName'] as String?)?.trim() ?? '';
//                 return cn == companyName || acn == companyName;
//               }).toList();

//               if (bins.isEmpty) {
//                 return const Center(child: Text("No bins assigned yet"));
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: bins.length,
//                 itemBuilder: (context, index) {
//                   final bin = bins[index].data();
//                   return _buildBinCard(
//                     context,
//                     (bin['id'] ?? 'N/A').toString(),
//                     (bin['location'] ?? 'N/A').toString(),
//                     (bin['capacity'] ?? 'N/A').toString(),
//                     (bin['companyName'] ??
//                             bin['assignedCompanyName'] ??
//                             'N/A')
//                         .toString(),
//                     (bin['sweeperId'] ?? bin['assignedSweeperId']) as String?,
//                     (bin['lastCleaned'] ?? 'Unknown').toString(),
//                     (bin['status'] ?? 'Unknown').toString(),
//                   );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildBinCard(
//     BuildContext context,
//     String binId,
//     String location,
//     String capacity,
//     String? companyName,
//     String? sweeperId,
//     String lastCleaned,
//     String status,
//   ) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 16.0),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Bin $binId",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(status),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     status,
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text("Location: $location"),
//             Text("Capacity: $capacity liters"),
//             Text("Last cleaned: $lastCleaned",
//                 style: const TextStyle(color: Colors.grey)),
//             const SizedBox(height: 12),
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 onPressed: () {
//                   _showDetailsDialog(
//                     context,
//                     binId,
//                     location,
//                     capacity,
//                     companyName,
//                     sweeperId,
//                     lastCleaned,
//                     status,
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1EDE5E),
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('View Details'),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDetailsDialog(
//     BuildContext context,
//     String binId,
//     String location,
//     String capacity,
//     String? companyName,
//     String? sweeperId,
//     String lastCleaned,
//     String status,
//   ) async {
//     String sweeperName = 'N/A';
//     if (sweeperId != null && sweeperId.isNotEmpty) {
//       final sweeperDoc = await FirebaseFirestore.instance
//           .collection('sweepers')
//           .doc(sweeperId)
//           .get();
//       if (sweeperDoc.exists) {
//         final data = sweeperDoc.data() as Map<String, dynamic>?;
//         sweeperName = (data?['name'] as String?) ?? 'N/A';
//       }
//     }

//     // ignore: use_build_context_synchronously
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Details for Bin $binId'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Location: $location'),
//             Text('Capacity: $capacity liters'),
//             Text('Company: ${companyName ?? 'N/A'}'),
//             Text('Assigned Sweeper: $sweeperName'),
//             Text('Last Cleaned: $lastCleaned'),
//             Text('Status: $status'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'complaint':
//         return Colors.purple;
//       case 'full':
//         return Colors.red;
//       case 'half':
//         return Colors.orange;
//       case 'empty':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }
// }

// lib/Company_bins.dart
// lib/Company_bins.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyBinsScreen extends StatelessWidget {
  const CompanyBinsScreen({super.key});

  Future<String?> _getCompanyUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id; // ✅ get company UID
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getCompanyUid(),
      builder: (context, companySnapshot) {
        if (companySnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final companyUid = companySnapshot.data;
        if (companyUid == null || companyUid.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No company found for this user")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'My Bins ($companyUid)',
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF1EDE5E),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bins')
                .where('assignedCompanyId',
                    isEqualTo: companyUid) // ✅ direct filter
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final bins = snapshot.data?.docs ?? const [];

              if (bins.isEmpty) {
                return const Center(child: Text("No bins assigned yet"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bins.length,
                itemBuilder: (context, index) {
                  final bin = bins[index].data();
                  return _buildBinCard(
                    context,
                    (bin['id'] ?? 'N/A').toString(),
                    (bin['location'] ?? 'N/A').toString(),
                    (bin['capacity'] ?? 'N/A').toString(),
                    (bin['assignedCompanyId'] ?? 'N/A').toString(),
                    (bin['sweeperId']) as String?,
                    (bin['lastCleaned'] ?? 'Unknown').toString(),
                    (bin['status'] ?? 'Unknown').toString(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBinCard(
    BuildContext context,
    String binId,
    String location,
    String capacity,
    String? companyId,
    String? sweeperId,
    String lastCleaned,
    String status,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bin $binId",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Location: $location"),
            Text("Capacity: $capacity liters"),
            Text("Last cleaned: $lastCleaned",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  _showDetailsDialog(
                    context,
                    binId,
                    location,
                    capacity,
                    companyId,
                    sweeperId,
                    lastCleaned,
                    status,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1EDE5E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Details'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    String binId,
    String location,
    String capacity,
    String? companyId,
    String? sweeperId,
    String lastCleaned,
    String status,
  ) async {
    String sweeperName = 'N/A';
    if (sweeperId != null && sweeperId.isNotEmpty) {
      final sweeperDoc = await FirebaseFirestore.instance
          .collection('sweepers')
          .doc(sweeperId)
          .get();
      if (sweeperDoc.exists) {
        final data = sweeperDoc.data();
        sweeperName = (data?['name'] as String?) ?? 'N/A';
      }
    }

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Details for Bin $binId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: $location'),
            Text('Capacity: $capacity liters'),
            Text('Assigned Company ID: ${companyId ?? 'N/A'}'),
            Text('Assigned Sweeper: $sweeperName'),
            Text('Last Cleaned: $lastCleaned'),
            Text('Status: $status'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'complaint':
        return Colors.purple;
      case 'full':
        return Colors.red;
      case 'half':
        return Colors.orange;
      case 'empty':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
