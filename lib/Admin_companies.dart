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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Edit zone
  void _showAssignZoneDialog(
      BuildContext context, String companyId, String currentArea) {
    final areaController = TextEditingController(text: currentArea);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Assign Zone'),
        content: TextField(
          controller: areaController,
          decoration: const InputDecoration(labelText: 'New Zone'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('companies')
                  .doc(companyId)
                  .update({'area': areaController.text.trim()});
              if (mounted) Navigator.pop(c);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  // Delete company -> unassign its bins (company + sweeper)
  Future<void> _deleteCompany(
      BuildContext context, String companyId, String companyName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          "Delete '$companyName'? This will unassign all its bins and sweepers from those bins.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final fs = FirebaseFirestore.instance;
      final batch = fs.batch();

      // Unassign all bins of this company
      final bins = await fs
          .collection('bins')
          .where('assignedCompanyId', isEqualTo: companyId)
          .get();

      for (final b in bins.docs) {
        batch.update(b.reference, {
          'assignedCompanyId': null,
          'assignedCompanyName': null,
          'assignedSweeperId':
              null, // also free any sweeper tied via those bins
        });
      }

      // Finally delete the company doc
      batch.delete(fs.collection('companies').doc(companyId));
      await batch.commit();

      if (mounted) Navigator.pop(context); // close loader
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Company '$companyName' deleted.")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  // A single card; counts are derived from bins where assignedCompanyId == company.id
  Widget _companyCard(Company company) {
    final fs = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs
          .collection('bins')
          .where('assignedCompanyId', isEqualTo: company.id)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
                title: Text('Loading...'), subtitle: Text('Please wait')),
          );
        }

        final binDocs = snap.data?.docs ?? const [];
        final binCount = binDocs.length;

        // Unique sweepers currently tied to this company's bins:
        final sweeperIds = <String>{};
        for (final d in binDocs) {
          final sid = (d.data()['assignedSweeperId'] ?? '').toString().trim();
          if (sid.isNotEmpty) sweeperIds.add(sid);
        }
        final sweeperCount = sweeperIds.length;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(company.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                "Area: ${company.area} • Bins: $binCount • Sweepers: $sweeperCount"),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      _showAssignZoneDialog(context, company.id, company.area),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _deleteCompany(context, company.id, company.name),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies Management'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by company name...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs
                  .collection('companies')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = (snap.data?.docs ?? const []).where((d) {
                  final m = d.data();
                  final name = (m['name'] ?? m['companyName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No companies found.'));
                }

                return ListView(
                  children: docs.map((d) {
                    final m = d.data();
                    final c = Company(
                      id: d.id,
                      name: (m['name'] ?? m['companyName'] ?? '').toString(),
                      area: (m['area'] ?? '').toString(),
                    );
                    return _companyCard(c);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}