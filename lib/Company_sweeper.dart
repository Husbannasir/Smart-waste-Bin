// lib/Company_sweeper.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanySweeper extends StatefulWidget {
  const CompanySweeper({super.key});

  @override
  State<CompanySweeper> createState() => _CompanySweeperState();
}

class _CompanySweeperState extends State<CompanySweeper> {
  String _searchText = '';

  /// Resolve login company name & ALL doc IDs that share that name
  Future<Map<String, dynamic>?> _getCompanyIdsAndName() async {
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
      displayName ??= (m['name'] ?? m['companyName'] ?? '').toString().trim();
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchSweepersByIds(
      List<String> ids) async {
    final fs = FirebaseFirestore.instance;
    final out = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final q = await fs
          .collection('sweepers')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      out.addAll(q.docs);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCompanyIdsAndName(),
      builder: (context, infoSnap) {
        if (infoSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final info = infoSnap.data;
        if (info == null) {
          return const Scaffold(
            body: Center(child: Text('Company not found')),
          );
        }

        final companyIds = Set<String>.from(info['ids'] as List);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sweepers Overview',
                style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: const Color(0xFF1EDE5E),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Sweepers',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Location or Name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _searchText = v.toLowerCase()),
                ),
                const SizedBox(height: 20),

                // 🔹 Stream ALL bins, filter locally by assignedCompanyId
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bins')
                        .snapshots(),
                    builder: (context, binsSnap) {
                      if (binsSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (binsSnap.hasError) {
                        return const Center(child: Text('Error loading bins'));
                      }

                      final docs = binsSnap.data?.docs ?? const [];
                      final sweeperIds = <String>{};

                      // Maps to build: locations per sweeper, cleanedToday per sweeper
                      final Map<String, Set<String>> locationsBySweeper = {};
                      final Map<String, int> cleanedTodayBySweeper = {};

                      final now = DateTime.now();
                      final startOfToday =
                          DateTime(now.year, now.month, now.day);

                      for (final d in docs) {
                        final m = d.data();
                        final cid = (m['assignedCompanyId'] ?? '').toString();
                        if (!companyIds.contains(cid)) continue;

                        final sid =
                            (m['assignedSweeperId'] ?? '').toString().trim();
                        if (sid.isEmpty) continue;
                        sweeperIds.add(sid);

                        // collect locations
                        final loc = (m['location'] ?? '').toString().trim();
                        if (loc.isNotEmpty) {
                          (locationsBySweeper[sid] ??= <String>{}).add(loc);
                        }

                        // count cleaned today (same logic as SweeperProfile)
                        final lcBy = (m['lastCleanedBy'] ?? '').toString();
                        final lcTs = m['lastCleaned'];
                        if (lcBy == sid && lcTs is Timestamp) {
                          final when = lcTs.toDate();
                          if (!when.isBefore(startOfToday)) {
                            cleanedTodayBySweeper[sid] =
                                (cleanedTodayBySweeper[sid] ?? 0) + 1;
                          }
                        }
                      }

                      if (sweeperIds.isEmpty) {
                        return const Center(
                            child: Text('No sweepers assigned by Admin.'));
                      }

                      return FutureBuilder<
                          List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                        future: _fetchSweepersByIds(sweeperIds.toList()),
                        builder: (context, swSnap) {
                          if (swSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (swSnap.hasError) {
                            return const Center(
                                child: Text('Error loading sweepers'));
                          }

                          final filtered = (swSnap.data ?? []).where((doc) {
                            final m = doc.data();
                            final name =
                                (m['name'] ?? '').toString().toLowerCase();
                            final locsStr = (locationsBySweeper[doc.id] ?? {})
                                .join(',')
                                .toLowerCase();
                            return _searchText.isEmpty ||
                                name.contains(_searchText) ||
                                locsStr.contains(_searchText);
                          }).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                                child: Text('No sweepers found.'));
                          }

                          return ListView(
                            children: filtered.map((doc) {
                              final m = doc.data();
                              final name = (m['name'] ?? 'Unknown').toString();

                              // Build location string from the bins mapped above
                              final locSet =
                                  locationsBySweeper[doc.id] ?? <String>{};
                              String locationText;
                              if (locSet.isEmpty) {
                                locationText = 'Unknown';
                              } else if (locSet.length <= 2) {
                                locationText = locSet.join(', ');
                              } else {
                                final firstTwo = locSet.take(2).join(', ');
                                locationText =
                                    '$firstTwo, +${locSet.length - 2} more';
                              }

                              final cleanedToday =
                                  cleanedTodayBySweeper[doc.id] ?? 0;

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text('Location: $locationText'),
                                      const SizedBox(height: 4),
                                      Text('Bins cleaned today: $cleanedToday'),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}