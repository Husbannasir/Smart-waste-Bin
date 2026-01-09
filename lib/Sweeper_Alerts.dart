import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SweeperAlertsScreen extends StatefulWidget {
  const SweeperAlertsScreen({super.key});

  @override
  State<SweeperAlertsScreen> createState() => _SweeperAlertsScreenState();
}

class _SweeperAlertsScreenState extends State<SweeperAlertsScreen> {
  final _db = FirebaseFirestore.instance;

  // 🔹 FIX: 'empty' ko yahan se hata diya taake alerts mein show na ho
  final _alertStatuses = const {
    'full',
    'half',
    'overflow',
    'complaint',
  };

  String _displayName(User? u) =>
      u?.displayName ?? (u?.email?.split('@').first ?? 'User');

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'overflow':
        return Colors.black87;
      case 'full':
        return Colors.redAccent;
      case 'half':
        return Colors.orangeAccent;
      case 'complaint':
        return Colors.purpleAccent;
      default:
        return const Color(0xFF00BFA5);
    }
  }

  Future<void> _markCleaned(DocumentReference<Map<String, dynamic>> ref) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Status update hote hi Firestore stream trigger hogi aur ye card list se hat jayega
    await ref.update({
      'status': 'Empty',
      'lastCleaned': FieldValue.serverTimestamp(),
      'lastCleanedBy': uid,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Bin Marked as Cleaned'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _resolveAll(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> alerts) async {
    if (alerts.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = _db.batch();
    for (final d in alerts) {
      batch.update(d.reference, {
        'status': 'Empty',
        'lastCleaned': FieldValue.serverTimestamp(),
        'lastCleanedBy': uid,
      });
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ Resolved ${alerts.length} alert(s)'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Material(
      color: Colors.transparent,
      child: uid == null
          ? const Center(child: Text('No user logged in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection('bins')
                  .where('assignedSweeperId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00BFA5)));
                }

                final docs = snap.data?.docs ?? const [];

                // 🔹 Real-time Filter: Sirf wahi bins jo 'empty' NAHI hain aur alert list mein hain
                final alerts = docs.where((d) {
                  final status =
                      (d.data()['status'] ?? '').toString().toLowerCase();
                  return status != 'empty' && _alertStatuses.contains(status);
                }).toList();

                final pendingComplaints = alerts
                    .where((d) =>
                        (d.data()['status'] ?? '').toString().toLowerCase() ==
                        'complaint')
                    .length;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hey, ${_displayName(user)}!',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00796B))),

                      // 🔹 Stats text automatically update hoga alerts.length se
                      Text(
                          alerts.isEmpty
                              ? 'All caught up! No active alerts.'
                              : 'You have ${alerts.length} active alerts to review.',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black54)),

                      const SizedBox(height: 25),

                      _buildAlertStats(alerts.length, pendingComplaints),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Alerts',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          if (alerts.isNotEmpty)
                            TextButton(
                              onPressed: () => _resolveAll(alerts),
                              child: const Text('Resolve All',
                                  style: TextStyle(
                                      color: Color(0xFF00BFA5),
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 🔹 Empty State UI
                      if (alerts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 80,
                                    color: Colors.green.withOpacity(0.3)),
                                const SizedBox(height: 15),
                                const Text('No pending alerts!',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black38,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...alerts.map((d) => _buildGlassyAlertCard(d)),

                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Card UI and Stats boxes remain same but now with fixed logic
  Widget _buildGlassyAlertCard(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    final status = (m['status'] ?? 'Unknown').toString();
    final chipColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BIN-${m['id']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: chipColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(status.toUpperCase(),
                          style: TextStyle(
                              color: chipColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(
                        child: Text(m['location'] ?? 'No Location',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _markCleaned(doc.reference),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Mark Cleaned',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertStats(int total, int complaints) {
    return Row(
      children: [
        _statBox('Total Alerts', total.toString(), Colors.blueAccent),
        const SizedBox(width: 15),
        _statBox('Complaints', complaints.toString(), Colors.purpleAccent),
      ],
    );
  }

  Widget _statBox(String title, String count, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
