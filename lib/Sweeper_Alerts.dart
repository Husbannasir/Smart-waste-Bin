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
  final _alertStatuses = const {
    'full',
    'half',
    'overflow',
    'complaint',
    'empty'
  };

  String _displayName(User? u) =>
      u?.displayName ?? (u?.email?.split('@').first ?? 'User');

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'overflow':
        return Colors.black;
      case 'full':
        return Colors.red;
      case 'half':
        return Colors.amber;
      case 'complaint':
        return Colors.purple;
      default:
        return const Color(0xFF2082DD);
    }
  }

  Future<void> _markCleaned(DocumentReference<Map<String, dynamic>> ref) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await ref.update({
      'status': 'Empty',
      'lastCleaned': FieldValue.serverTimestamp(),
      'lastCleanedBy': uid,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Marked as cleaned')),
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
        SnackBar(content: Text('✅ Resolved ${alerts.length} alert(s)')),
      );
    }
  }

  void _showDetailsDialog(Map<String, dynamic> m) {
    final id = (m['id'] ?? 'N/A').toString();
    final location = (m['location'] ?? 'N/A').toString();
    final capacity = (m['capacity'] ?? 'N/A').toString();
    final status = (m['status'] ?? 'Unknown').toString();
    final company =
        (m['assignedCompanyName'] ?? m['companyName'] ?? 'N/A').toString();
    final sweeper = (m['assignedSweeperName'] ?? 'N/A').toString();
    final last = m['lastCleaned'] is Timestamp
        ? (m['lastCleaned'] as Timestamp).toDate().toString()
        : '—';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Bin $id Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: $location'),
            Text('Capacity: $capacity liters'),
            Text('Company: $company'),
            Text('Assigned Sweeper: $sweeper'),
            Text('Status: $status'),
            Text('Last Cleaned: $last'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sweepers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('No user logged in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // Stream only the bins assigned to this sweeper (filter statuses locally)
              stream: _db
                  .collection('bins')
                  .where('assignedSweeperId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final assigned = snap.data?.docs ?? const [];

                // Only alerts: Full/Half/Overflow/Complaint
                final alerts = assigned
                    .where((d) => _alertStatuses.contains(
                        (d.data()['status'] ?? '').toString().toLowerCase()))
                    .toList();

                final pendingComplaints = alerts
                    .where((d) =>
                        (d.data()['status'] ?? '').toString().toLowerCase() ==
                        'complaint')
                    .length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_displayName(user)}!',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'You have ${alerts.length} alerts and $pendingComplaints pending complaints to review',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Alerts',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: alerts.isEmpty
                                ? null
                                : () => _resolveAll(alerts),
                            child: const Text('Resolve All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (alerts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(child: Text('No alerts right now.')),
                        )
                      else
                        ...alerts.map((d) {
                          final m = d.data();
                          final id = (m['id'] ?? 'N/A').toString();
                          final status = (m['status'] ?? 'Unknown').toString();
                          final location = (m['location'] ?? '—').toString();
                          final chipColor = _statusColor(status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(id,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      Chip(
                                        label: Text(status.toUpperCase()),
                                        backgroundColor: chipColor,
                                        labelStyle: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(location,
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            _markCleaned(d.reference),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF19CD55)),
                                        child: const Text('Mark as Cleaned',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _showDetailsDialog(m),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF2082DD)),
                                        child: const Text('View Details',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}