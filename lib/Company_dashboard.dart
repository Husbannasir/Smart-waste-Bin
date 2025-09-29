import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Intro.dart';

class CompanyDashboard extends StatelessWidget {
  const CompanyDashboard({super.key});

  /// Resolve logged-in company:
  /// returns { name: String, ids: List<String> }  (all docIds that share that name/email)
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

    // If we got a name, also collect any other docs that have the same name/companyName.
    if ((displayName ?? '').isNotEmpty) {
      final byName = await fs
          .collection('companies')
          .where('name', isEqualTo: displayName)
          .get();
      for (final d in byName.docs) {
        ids.add(d.id);
      }

      final byCompanyName = await fs
          .collection('companies')
          .where('companyName', isEqualTo: displayName)
          .get();
      for (final d in byCompanyName.docs) {
        ids.add(d.id);
      }
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final info = infoSnap.data;
        if (info == null) {
          return const Scaffold(
            body: Center(child: Text('No Data Found')),
          );
        }

        final displayName = (info['name'] as String?)?.trim() ?? 'My Company';
        final companyIds = Set<String>.from(info['ids'] as List);
        final title = '$displayName Dashboard';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.green,
            title: Text(title),
            actions: [
              PopupMenuButton<int>(
                icon: const Icon(Icons.account_circle),
                onSelected: (item) async {
                  if (item == 0) {
                    await FirebaseAuth.instance.signOut();
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const IntroScreen()),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<int>(value: 0, child: Text("Logout")),
                ],
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: fs.collection('bins').snapshots(),
            builder: (context, binsSnap) {
              if (binsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // ---- Stats from bins assigned to this company ----
              final binDocs = binsSnap.data?.docs ?? const [];
              int totalBins = 0;
              int fullBins = 0;
              final sweeperIds = <String>{};

              for (final d in binDocs) {
                final m = d.data();
                final cid = (m['assignedCompanyId'] ?? '').toString();
                if (!companyIds.contains(cid)) continue;

                totalBins++;
                final status = (m['status'] ?? '').toString().toLowerCase();
                if (status == 'full') fullBins++;

                final sid = (m['assignedSweeperId'] ?? '').toString().trim();
                if (sid.isNotEmpty) sweeperIds.add(sid);
              }

              final sweepers = sweeperIds.length;
              final efficiency = totalBins == 0
                  ? 0.0
                  : ((totalBins - fullBins) / totalBins * 100);

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        title, // e.g., "Evergreen Dashboard"
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Welcome to your dashboard",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---- Stats Row ----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statCard("$totalBins", "Total Bins", Colors.blue),
                          _statCard("$fullBins", "Full Bins", Colors.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statCard("$sweepers", "Sweepers", Colors.orange),
                          _statCard(
                            "${efficiency.toStringAsFixed(1)}%",
                            "Efficiency",
                            Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Sweeper Reports",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---- STABLE REPORTS STREAM ----
                    // Single live stream for all reports (ordered),
                    // then local filter by companyName (case-insensitive)
                    // OR optional companyId (if you later add it to reports).
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: fs
                          .collection('reports')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, repSnap) {
                        if (repSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final all = repSnap.data?.docs ?? const [];
                        final dn = displayName.trim().toLowerCase();

                        final reports = all.where((d) {
                          final m = d.data();
                          final nameLower = (m['companyName'] ?? '')
                              .toString()
                              .trim()
                              .toLowerCase();
                          final cid = (m['companyId'] ?? '').toString();
                          return (nameLower == dn) || companyIds.contains(cid);
                        }).toList();

                        if (reports.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text("No reports submitted yet."),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reports.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            final doc = reports[i];
                            final r = doc.data();

                            final sweeperName =
                                (r['sweeperName'] ?? 'Unknown').toString();
                            final issue =
                                (r['issueType'] ?? r['issue'] ?? 'Unknown')
                                    .toString();
                            final desc =
                                (r['description'] ?? 'No details').toString();
                            final binId = (r['binId'] ?? 'N/A').toString();
                            final ts = r['timestamp'] as Timestamp?;
                            final when = _formatTs(ts);

                            final issueColor = _issueColor(issue);

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            sweeperName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Delete button
                                        IconButton(
                                          tooltip: 'Delete report',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text(
                                                    'Delete report?'),
                                                content: const Text(
                                                  'This action cannot be undone.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true) {
                                              await doc.reference.delete();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Issue chip + Bin id
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Chip(
                                          label: Text(issue),
                                          labelStyle: const TextStyle(
                                              color: Colors.white),
                                          backgroundColor: issueColor,
                                        ),
                                        Chip(
                                          label: Text('BIN-$binId'),
                                          backgroundColor: Colors.grey.shade200,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    _kv('Description', desc),
                                    _kv('Time', when),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- UI helpers ----------------

  Widget _statCard(String value, String label, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$k:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Color _issueColor(String issue) {
    switch (issue.toLowerCase()) {
      case 'overflow':
        return Colors.red;
      case 'damaged':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';
  String _formatTs(Timestamp? ts) {
    if (ts == null) return 'pending…';
    final d = ts.toDate();
    final y = d.year, mo = _two(d.month), da = _two(d.day);
    final h = _two(d.hour), mi = _two(d.minute), s = _two(d.second);
    return '$y-$mo-$da $h:$mi:$s';
  }
}
