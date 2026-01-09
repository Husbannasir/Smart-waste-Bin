import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String area;
  Company({required this.id, required this.name, required this.area});
}

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});
  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // 🔹 Assign Zone Dialog (Styled)
  void _showAssignZoneDialog(
      BuildContext context, String companyId, String currentArea) {
    final areaController = TextEditingController(text: currentArea);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Assign Service Zone',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: areaController,
          decoration: InputDecoration(
            labelText: 'New Zone / Area',
            prefixIcon:
                const Icon(Icons.map_outlined, color: Color(0xFF22B5FE)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22B5FE),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await _firestore
                  .collection('companies')
                  .doc(companyId)
                  .update({'area': areaController.text.trim()});
              if (mounted) Navigator.pop(c);
            },
            child:
                const Text('Assign Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔹 Delete Company logic (Unchanged, just Snackbars styled)
  Future<void> _deleteCompany(
      BuildContext context, String companyId, String companyName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Confirm Delete'),
        content: Text(
            "Delete '$companyName'? This will unassign all its bins and sweepers."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final fs = FirebaseFirestore.instance;
      final batch = fs.batch();
      final bins = await fs
          .collection('bins')
          .where('assignedCompanyId', isEqualTo: companyId)
          .get();

      for (final b in bins.docs) {
        batch.update(b.reference, {
          'assignedCompanyId': null,
          'assignedCompanyName': null,
          'assignedSweeperId': null
        });
      }

      batch.delete(fs.collection('companies').doc(companyId));
      await batch.commit();

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ Company Deleted"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    }
  }

  // 🔹 Modern Company Card (FIXED OVERFLOW)
  Widget _companyCard(Company company) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('bins')
          .where('assignedCompanyId', isEqualTo: company.id)
          .snapshots(),
      builder: (context, snap) {
        final binDocs = snap.data?.docs ?? const [];
        final binCount = binDocs.length;
        final sweeperIds = <String>{};
        for (final d in binDocs) {
          final sid = (d.data()['assignedSweeperId'] ?? '').toString().trim();
          if (sid.isNotEmpty) sweeperIds.add(sid);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF22B5FE).withOpacity(0.1),
              child:
                  const Icon(Icons.business_rounded, color: Color(0xFF22B5FE)),
            ),
            title: Text(company.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF2D3142))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("📍 Area: ${company.area}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                // 🔹 FIXED: Wrap widget automatic next line mein le jayega agar overflow ho
                Wrap(
                  spacing: 8, // Chips ke darmiyan gap
                  runSpacing: 4, // Agli line mein jaye toh gap
                  children: [
                    _infoChip(
                        Icons.delete_outline, "$binCount Bins", Colors.blue),
                    _infoChip(Icons.people_outline,
                        "${sweeperIds.length} Sweepers", Colors.green),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              onSelected: (val) {
                if (val == 'edit')
                  _showAssignZoneDialog(context, company.id, company.area);
                if (val == 'delete')
                  _deleteCompany(context, company.id, company.name);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text("Edit Zone")
                    ])),
                const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Delete", style: TextStyle(color: Colors.red))
                    ])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            // 🔹 Text ko overflow se bachane ke liye
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        centerTitle: true,
        title: const Text("Companies Management",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 🔹 Glassy Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF22B5FE)),
                  hintText: 'Search company by name...',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('companies')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snap.data!.docs.where((d) {
                  final name =
                      (d.data()['name'] ?? d.data()['companyName'] ?? '')
                          .toString()
                          .toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No companies found.',
                          style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final m = d.data();
                    final c = Company(
                      id: d.id,
                      name: (m['name'] ?? m['companyName'] ?? '').toString(),
                      area: (m['area'] ?? '').toString(),
                    );
                    return _companyCard(c);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
