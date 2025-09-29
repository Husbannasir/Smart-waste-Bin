import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ NEW
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
  String? _sweeperDocId; // sweepers/<docId>
  String? _sweeperName; // optional, for greeting

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
    final authUid = u?.uid;

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

    // fallback: docId == auth uid
    docId ??= authUid;

    setState(() {
      _sweeperDocId = docId;
      _sweeperName = name ?? userName;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sweeperDocId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            const Text('Sweepers Panel', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _isOnBreak
                ? 'You are on break'
                : 'Good Morning, ${_sweeperName ?? userName}!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isOnBreak ? Colors.orange : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          if (!_isOnBreak) ...[
            _tasksSection(),
            const SizedBox(height: 24),
          ],
          _quickActions(),
        ]),
      ),
    );
  }

  Widget _tasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Tasks",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _chip('ALL'),
            _chip('FULL'),
            _chip('HALF'),
            _chip('EMPTY')
          ],
        ),
        const SizedBox(height: 16),

        // 🔒 Only bins assigned to this sweeper
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
              return const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('No tasks found.')),
              );
            }

            return Column(
              children: docs.map((d) {
                final m = d.data();
                final binId = (m['id'] ?? 'N/A').toString();
                final status =
                    (m['status'] ?? 'Unknown').toString().toUpperCase();
                final location = (m['location'] ?? '').toString();

                // ✅ If you store coordinates in Firestore, e.g. lat/lng
                final double? lat =
                    (m['lat'] is num) ? (m['lat'] as num).toDouble() : null;
                final double? lng =
                    (m['lng'] is num) ? (m['lng'] as num).toDouble() : null;

                return _taskCard(
                  binId: binId,
                  status: status,
                  location: location,
                  onMarkCleaned: () async {
                    await d.reference.update({
                      'status': 'Empty',
                      'lastCleaned': FieldValue.serverTimestamp(),
                      'cleanedBy': _sweeperDocId,
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked as cleaned')),
                      );
                    }
                  },
                  onNavigate: () =>
                      _openMaps(location, lat: lat, lng: lng), // ✅
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _chip(String label) {
    final sel = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (v) => setState(() => _selectedFilter = label),
      backgroundColor: const Color.fromARGB(255, 116, 114, 114),
      selectedColor: label == 'ALL'
          ? const Color(0xFF19CD55)
          : label == 'FULL'
              ? Colors.red
              : label == 'HALF'
                  ? Colors.orange
                  : Colors.lightBlue,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Widget _taskCard({
    required String binId,
    required String status,
    required String location,
    required VoidCallback onMarkCleaned,
    required VoidCallback onNavigate,
  }) {
    final bg = status == 'FULL'
        ? Colors.red
        : status == 'HALF'
            ? Colors.orange
            : status == 'CLEANED'
                ? Colors.green
                : Colors.lightBlue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('BIN-$binId',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
                label: Text(status),
                backgroundColor: bg,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 10)),
          ]),
          const SizedBox(height: 8),
          Text(location, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Row(children: [
            ElevatedButton(
              onPressed: onMarkCleaned,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19CD55)),
              child: const Text('Mark as Cleaned',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onNavigate,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2082DD)),
              child:
                  const Text('Navigate', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ]),
      ),
    );
  }

  // ✅ Launch Google Maps with lat/lng (preferred) OR with address text
  Future<void> _openMaps(String location, {double? lat, double? lng}) async {
    Uri? uri;

    if (lat != null && lng != null) {
      // Lat/Lng present in Firestore
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else if (location.trim().isNotEmpty) {
      final q = Uri.encodeComponent(location.trim());
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }

    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location to navigate')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps')),
      );
    }
  }

  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _actionCard(Icons.report_problem, 'Report Issue', Colors.red, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SweeperReportsScreen()));
          }),
          _actionCard(_isOnBreak ? Icons.play_arrow : Icons.free_breakfast,
              _isOnBreak ? 'Resume Work' : 'Take Break', Colors.orange, () {
            setState(() => _isOnBreak = !_isOnBreak);
          }),
          _actionCard(Icons.work_off, 'End Shift', const Color(0xFF2082DD), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const IntroScreen()),
              (r) => false,
            );
          }),
        ]),
      ],
    );
  }

  Widget _actionCard(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 100,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}