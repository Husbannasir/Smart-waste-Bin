import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Intro.dart';

class CompanyDashboard extends StatelessWidget {
  const CompanyDashboard({super.key});

  // 🔹 Logic remains exactly same for stability
  Future<Map<String, dynamic>?> _getCompanyInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final fs = FirebaseFirestore.instance;
    final byEmail = await fs
        .collection('companies')
        .where('email', isEqualTo: user.email)
        .get();

    String? displayName;
    final ids = <String>{};
    for (final d in byEmail.docs) {
      ids.add(d.id);
      final m = d.data();
      final n = (m['name'] ?? m['companyName'] ?? '').toString().trim();
      if (n.isNotEmpty) displayName = n;
    }

    if ((displayName ?? '').isNotEmpty) {
      final byName = await fs
          .collection('companies')
          .where('name', isEqualTo: displayName)
          .get();
      for (final d in byName.docs) ids.add(d.id);
      final byCompanyName = await fs
          .collection('companies')
          .where('companyName', isEqualTo: displayName)
          .get();
      for (final d in byCompanyName.docs) ids.add(d.id);
    }

    if (ids.isEmpty) return null;
    return {'name': displayName ?? 'My Company', 'ids': ids.toList()};
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCompanyInfo(),
      builder: (context, infoSnap) {
        if (infoSnap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2979FF)));
        }
        final info = infoSnap.data;
        if (info == null)
          return const Center(child: Text('No Company Data Found'));

        final displayName = (info['name'] as String?)?.trim() ?? 'Company';
        final companyIds = Set<String>.from(info['ids'] as List);

        return Material(
          // 🔹 Material wrapper for ink splashes and clicks
          color: Colors.transparent,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: fs.collection('bins').snapshots(),
            builder: (context, binsSnap) {
              if (!binsSnap.hasData)
                return const Center(child: CircularProgressIndicator());

              // ---- Real-time Stats Logic ----
              final binDocs = binsSnap.data!.docs;
              int totalBins = 0;
              int fullBins = 0;
              final sweeperIds = <String>{};

              for (final d in binDocs) {
                final m = d.data();
                final cid =
                    (m['assignedCompanyId'] ?? m['companyId'] ?? '').toString();
                if (!companyIds.contains(cid)) continue;

                totalBins++;
                if ((m['status'] ?? '').toString().toLowerCase() == 'full')
                  fullBins++;
                final sid = (m['assignedSweeperId'] ?? '').toString().trim();
                if (sid.isNotEmpty) sweeperIds.add(sid);
              }

              final efficiency = totalBins == 0
                  ? 0.0
                  : ((totalBins - fullBins) / totalBins * 100);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome back,",
                        style: TextStyle(color: Colors.black54, fontSize: 16)),
                    Text(displayName,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0))),

                    const SizedBox(height: 25),

                    // 🔹 LIVE STATS GRID
                    Row(
                      children: [
                        _statCard("Total Bins", totalBins.toString(),
                            Icons.delete_sweep_rounded, Colors.blueAccent),
                        const SizedBox(width: 15),
                        _statCard("Full Bins", fullBins.toString(),
                            Icons.warning_amber_rounded, Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _statCard("Sweepers", sweeperIds.length.toString(),
                            Icons.people_alt_rounded, Colors.orangeAccent),
                        const SizedBox(width: 15),
                        _statCard(
                            "Efficiency",
                            "${efficiency.toStringAsFixed(1)}%",
                            Icons.bolt_rounded,
                            Colors.green),
                      ],
                    ),

                    const SizedBox(height: 35),
                    const Text("Recent Sweeper Reports",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0))),
                    const SizedBox(height: 15),

                    // 🔹 LIVE REPORTS LIST
                    _buildReportsStream(fs, displayName, companyIds),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 🔹 Glassy Stat Card Helper
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Reports Stream with Glassy Cards
  Widget _buildReportsStream(
      FirebaseFirestore fs, String displayName, Set<String> companyIds) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, repSnap) {
        if (!repSnap.hasData)
          return const Center(child: CircularProgressIndicator());

        final dn = displayName.trim().toLowerCase();
        final reports = repSnap.data!.docs.where((d) {
          final m = d.data();
          final nameLower = (m['companyName'] ?? '').toString().toLowerCase();
          final cid =
              (m['companyId'] ?? m['assignedCompanyId'] ?? '').toString();
          return (nameLower == dn) || companyIds.contains(cid);
        }).toList();

        if (reports.isEmpty) return const Text("No reports submitted yet.");

        return Column(
          children: reports.map((doc) => _reportCard(context, doc)).toList(),
        );
      },
    );
  }

  Widget _reportCard(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final r = doc.data();
    final issue = (r['issueType'] ?? r['issue'] ?? 'Unknown').toString();
    final ts = r['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r['sweeperName'] ?? 'Sweeper',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 22),
                      onPressed: () => _confirmDelete(context, doc),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(issue, _issueColor(issue)),
                    _chip('BIN-${r['binId']}', Colors.blueGrey.shade400),
                  ],
                ),
                const SizedBox(height: 12),
                Text(r['description'] ?? 'No details',
                    style:
                        const TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 8),
                Text(_formatTs(ts),
                    style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  // 🔹 Helper functions logic preserved
  Color _issueColor(String issue) {
    switch (issue.toLowerCase()) {
      case 'overflow':
        return Colors.red;
      case 'damaged':
        return const Color.fromARGB(255, 255, 39, 39);
      default:
        return Colors.blueGrey;
    }
  }

  String _formatTs(Timestamp? ts) {
    if (ts == null) return 'Pending…';
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}";
  }

  Future<void> _confirmDelete(
      BuildContext context, QueryDocumentSnapshot doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text(
            'This will permanently remove this report from your dashboard.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await doc.reference.delete();
  }
}
