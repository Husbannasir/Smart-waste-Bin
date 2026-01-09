import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
    return snap.docs.first.id;
  }

  String _formatTimestamp(dynamic value) {
    if (value == null) return 'Not cleaned yet';
    try {
      final fmt = DateFormat('dd MMM, h:mm a');
      if (value is Timestamp) return fmt.format(value.toDate().toLocal());
    } catch (_) {}
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getCompanyUid(),
      builder: (context, companySnapshot) {
        if (companySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        final companyUid = companySnapshot.data;
        if (companyUid == null) {
          return const Center(
              child: Text("No company found",
                  style: TextStyle(color: Colors.white, fontSize: 18)));
        }

        return Material(
          color: Colors.transparent,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bins')
                .where('assignedCompanyId', isEqualTo: companyUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }

              final bins = snapshot.data!.docs;
              if (bins.isEmpty) {
                return const Center(
                    child: Text("No bins assigned yet",
                        style: TextStyle(color: Colors.white70, fontSize: 16)));
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: bins.length,
                itemBuilder: (context, index) {
                  final data = bins[index].data();
                  return _buildHighContrastCard(
                    context: context,
                    data: data,
                    binId: (data['id'] ?? 'N/A').toString(),
                    location: (data['location'] ?? 'N/A').toString(),
                    status: (data['status'] ?? 'Unknown').toString(),
                    lastCleaned: _formatTimestamp(data['lastCleaned']),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHighContrastCard({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String binId,
    required String location,
    required String status,
    required String lastCleaned,
  }) {
    Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border:
                  Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("BIN-$binId",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    _statusChip(status, statusColor),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(location,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showDetailsDialog(context, data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 59, 102, 243),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("VIEW DETAILS",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 FIX: Yahan ab sweeper ka naam fetch ho raha hai Firestore se
  void _showDetailsDialog(
      BuildContext context, Map<String, dynamic> data) async {
    String sweeperId = data['assignedSweeperId'] ?? data['sweeperId'] ?? '';
    String sweeperName = "Not Assigned";

    // Show loading dialog briefly if fetching takes time
    if (sweeperId.isNotEmpty) {
      try {
        var sweeperDoc = await FirebaseFirestore.instance
            .collection('sweepers')
            .doc(sweeperId)
            .get();
        if (sweeperDoc.exists) {
          sweeperName = sweeperDoc.data()?['name'] ?? "Unknown Sweeper";
        }
      } catch (e) {
        sweeperName = "Error fetching name";
      }
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 34, 65, 240),
        // 🔹 'borderSide' ki jagah sirf 'side' use karein
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24),
        ),
        title: Text(
          "Bin ${data['id']} Details",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row("Location", data['location']),
            _row("Status", data['status']),
            _row("Capacity", "${data['capacity']} L"),
            _row("Sweeper", sweeperName),
            _row("Last Cleaned", _formatTimestamp(data['lastCleaned'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Close", style: TextStyle(color: Colors.cyanAccent)),
          )
        ],
      ),
    );
  }

  Widget _row(String label, String? val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:",
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(val ?? 'N/A',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'full':
        return Colors.red;
      case 'half':
        return Colors.orange;
      case 'empty':
        return Colors.greenAccent;
      default:
        return Colors.blue;
    }
  }
}
