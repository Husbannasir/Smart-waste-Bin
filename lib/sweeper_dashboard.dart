import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Intro.dart';
import 'Sweeper_reports.dart';

class SweeperDashboardScreen extends StatefulWidget {
  const SweeperDashboardScreen({super.key});
  @override
  State<SweeperDashboardScreen> createState() => _SweeperDashboardScreenState();
}

class _SweeperDashboardScreenState extends State<SweeperDashboardScreen> {
  String _selectedFilter = 'ALL';
  bool _isOnBreak = false;
  String userName = 'User';
  String? _sweeperDocId;
  String? _sweeperName;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    userName = u?.displayName ?? u?.email?.split('@').first ?? 'User';
    _resolveSweeperDocId();
  }

  Future<void> _resolveSweeperDocId() async {
    final u = FirebaseAuth.instance.currentUser;
    final email = u?.email;
    final f = FirebaseFirestore.instance;
    String? docId;
    String? name;

    if (email != null && email.isNotEmpty) {
      final q = await f
          .collection('sweepers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        docId = q.docs.first.id;
        name = (q.docs.first.data()['name'] as String?)?.trim();
      }
    }
    docId ??= u?.uid;
    setState(() {
      _sweeperDocId = docId;
      _sweeperName = name ?? userName;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sweeperDocId == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)));
    }

    return Material(
      color: Colors
          .transparent, // 🔹 Background transparent taake Panel ka gradient nazar aaye
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Modern Greeting
            Text(
              _isOnBreak ? 'Resting...' : 'Good Morning,',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            Text(
              _sweeperName ?? userName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isOnBreak ? Colors.orange : const Color(0xFF00796B),
              ),
            ),

            const SizedBox(height: 30),

            if (!_isOnBreak) ...[
              _buildModernTasksSection(),
              const SizedBox(height: 30),
            ],

            _buildModernQuickActions(),
            const SizedBox(
                height: 120), // 🔹 Bottom Nav Bar ke liye extra space
          ],
        ),
      ),
    );
  }

  Widget _buildModernTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Progress",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 15),

        // 🔹 Glassy Filter Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'FULL', 'HALF', 'EMPTY']
                .map((label) => _buildModernChip(label))
                .toList(),
          ),
        ),

        const SizedBox(height: 20),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bins')
              .where('assignedSweeperId', isEqualTo: _sweeperDocId)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = (snap.data?.docs ?? []).where((d) {
              final s = (d.data()['status'] ?? '').toString().toUpperCase();
              return _selectedFilter == 'ALL' || s == _selectedFilter;
            }).toList();

            if (docs.isEmpty) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('No tasks found.',
                    style: TextStyle(color: Colors.black38)),
              ));
            }

            return Column(
              children: docs.map((d) {
                final m = d.data();
                return _buildGlassTaskCard(
                  doc: d,
                  binId: (m['id'] ?? 'N/A').toString(),
                  status: (m['status'] ?? 'Unknown').toString().toUpperCase(),
                  location: (m['location'] ?? '').toString(),
                  lat: (m['lat'] is num) ? (m['lat'] as num).toDouble() : null,
                  lng: (m['lng'] is num) ? (m['lng'] as num).toDouble() : null,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildModernChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BFA5)
              : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGlassTaskCard({
    required QueryDocumentSnapshot doc,
    required String binId,
    required String status,
    required String location,
    double? lat,
    double? lng,
  }) {
    Color statusColor = status == 'FULL'
        ? Colors.redAccent
        : (status == 'HALF' ? Colors.orangeAccent : Colors.greenAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BIN-$binId',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(location,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await doc.reference.update({
                            'status': 'Empty',
                            'lastCleaned': FieldValue.serverTimestamp(),
                            'lastCleanedBy': _sweeperDocId,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Mark Cleaned',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => _openMaps(location, lat: lat, lng: lng),
                      icon: const Icon(Icons.directions_rounded,
                          color: Color(0xFF2082DD)),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionIcon(Icons.report_problem, 'Report', Colors.redAccent, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SweeperReportsScreen()));
        }),
        _buildActionIcon(_isOnBreak ? Icons.play_arrow : Icons.coffee,
            _isOnBreak ? 'Resume' : 'Break', Colors.orange, () {
          setState(() => _isOnBreak = !_isOnBreak);
        }),
        _buildActionIcon(
            Icons.logout_rounded, 'Logout', const Color(0xFF2082DD), () {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const IntroScreen()),
              (r) => false);
        }),
      ],
    );
  }

  Widget _buildActionIcon(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMaps(String location, {double? lat, double? lng}) async {
    final String googleMapsUrl = (lat != null && lng != null)
        ? "https://www.google.com/maps/search/?api=1&query=$lat,$lng"
        : "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}";

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication);
    }
  }
}
