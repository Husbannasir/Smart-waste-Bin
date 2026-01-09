import 'dart:ui';
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

  // Logic to fetch company info
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
    return ids.isEmpty
        ? null
        : {'name': displayName ?? 'My Company', 'ids': ids.toList()};
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
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        final info = infoSnap.data;
        if (info == null)
          return const Center(
              child: Text('Company not found',
                  style: TextStyle(color: Colors.white)));

        final companyIds = Set<String>.from(info['ids'] as List);

        return Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildSearchBar(),
                const SizedBox(height: 25),
                const Text('Active Staff',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 15),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bins')
                        .snapshots(),
                    builder: (context, binsSnap) {
                      if (!binsSnap.hasData)
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white));

                      final docs = binsSnap.data!.docs;
                      final sweeperIds = <String>{};
                      final Map<String, Set<String>> locationsBySweeper = {};
                      final Map<String, int> cleanedTodayBySweeper = {};
                      final startOfToday = DateTime(DateTime.now().year,
                          DateTime.now().month, DateTime.now().day);

                      for (final d in docs) {
                        final m = d.data();
                        if (!companyIds.contains(
                            (m['assignedCompanyId'] ?? '').toString()))
                          continue;

                        final sid =
                            (m['assignedSweeperId'] ?? '').toString().trim();
                        if (sid.isEmpty) continue;
                        sweeperIds.add(sid);

                        final loc = (m['location'] ?? '').toString().trim();
                        if (loc.isNotEmpty)
                          (locationsBySweeper[sid] ??= <String>{}).add(loc);

                        if (m['lastCleanedBy'] == sid &&
                            m['lastCleaned'] is Timestamp) {
                          if (!(m['lastCleaned'] as Timestamp)
                              .toDate()
                              .isBefore(startOfToday)) {
                            cleanedTodayBySweeper[sid] =
                                (cleanedTodayBySweeper[sid] ?? 0) + 1;
                          }
                        }
                      }

                      return FutureBuilder<
                          List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                        future: _fetchSweepersByIds(sweeperIds.toList()),
                        builder: (context, swSnap) {
                          if (!swSnap.hasData)
                            return const Center(
                                child: CircularProgressIndicator());

                          final filtered = swSnap.data!.where((doc) {
                            final name = (doc.data()['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            final locsStr = (locationsBySweeper[doc.id] ?? {})
                                .join(',')
                                .toLowerCase();
                            return _searchText.isEmpty ||
                                name.contains(_searchText) ||
                                locsStr.contains(_searchText);
                          }).toList();

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final sweeperDoc = filtered[index];
                              final sweeperLocs =
                                  locationsBySweeper[sweeperDoc.id];
                              final sweeperCleaned =
                                  cleanedTodayBySweeper[sweeperDoc.id] ?? 0;

                              // 🔹 Added GestureDetector for clicking
                              return GestureDetector(
                                onTap: () => _showSweeperDetails(
                                    context, sweeperDoc.data(), sweeperLocs),
                                child: _buildHighContrastSweeperCard(
                                    sweeperDoc, sweeperLocs, sweeperCleaned),
                              );
                            },
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

  // 🔹 New Detail Dialog Function
  void _showSweeperDetails(BuildContext context,
      Map<String, dynamic> sweeperData, Set<String>? areas) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A237E).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.cyanAccent, width: 1),
          ),
          title: Row(
            children: [
              const Icon(Icons.badge, color: Colors.cyanAccent),
              const SizedBox(width: 10),
              Text(sweeperData['name'] ?? 'Staff Details',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Assigned Areas:",
                  style: TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (areas == null || areas.isEmpty)
                const Text("No areas assigned.",
                    style: TextStyle(color: Colors.white70))
              else
                ...areas.map((area) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(area,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14))),
                        ],
                      ),
                    )),
              const Divider(color: Colors.white24, height: 25),
              Text(
                  "Contact: ${sweeperData['phone'] ?? sweeperData['email'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE",
                  style: TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: TextField(
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'Find Staff or Area...',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: Colors.cyanAccent),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildHighContrastSweeperCard(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Set<String>? locs,
      int cleaned) {
    final name = (doc.data()['name'] ?? 'Unknown').toString();
    String locationText = (locs == null || locs.isEmpty)
        ? 'No Area Assigned'
        : (locs.length <= 1
            ? locs.first
            : '${locs.first} & ${locs.length - 1} more');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent, width: 1)),
                  child: Center(
                      child: Text(name[0],
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 22,
                              fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(locationText,
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5)),
                            child: Text("Today: $cleaned Cleaned",
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.info_outline,
                    color: Colors.cyanAccent,
                    size: 20), // 🔹 Info icon to show it's clickable
              ],
            ),
          ),
        ),
      ),
    );
  }
}
