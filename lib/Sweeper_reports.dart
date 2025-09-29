import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SweeperReportsScreen extends StatefulWidget {
  const SweeperReportsScreen({super.key});

  @override
  State<SweeperReportsScreen> createState() => _SweeperReportsScreenState();
}

class _SweeperReportsScreenState extends State<SweeperReportsScreen> {
  final TextEditingController _binIdController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  String? _selectedIssue;
  bool _resolvingCompany = false;

  // ✅ keep the resolved companyId in state (so we can save it with the report)
  String? _resolvedCompanyId;

  // ------------------ helpers: resolve company (id + name) from Bin ------------------
  Future<Map<String, String?>> _getCompanyFromBin(String binId) async {
    // ✅ Properly typed map with nullable values
    final Map<String, String?> out = {'id': null, 'name': null};
    final id = binId.trim();
    if (id.isEmpty) return out;

    final f = FirebaseFirestore.instance;

    // bins have a field "id": "204" (not the docId). Query by that:
    final q =
        await f.collection('bins').where('id', isEqualTo: id).limit(1).get();
    if (q.docs.isEmpty) return out;

    final m = q.docs.first.data();
    final cid = (m['assignedCompanyId'] ?? '').toString().trim();
    final cname = ((m['assignedCompanyName'] ?? m['companyName']) ?? '')
        .toString()
        .trim();

    // Best effort: if name is missing but we have an id, look up companies/<id>
    String? finalName = cname.isNotEmpty ? cname : null;
    if (finalName == null && cid.isNotEmpty) {
      final comp = await f.collection('companies').doc(cid).get();
      if (comp.exists) {
        final cm = comp.data() as Map<String, dynamic>;
        finalName = ((cm['name'] ?? cm['companyName']) ?? '').toString().trim();
      }
    }

    out['id'] = cid.isEmpty ? null : cid;
    out['name'] = (finalName == null || finalName.isEmpty) ? null : finalName;
    return out;
  }

  Future<String?> _resolveSweeperName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final f = FirebaseFirestore.instance;

    // try: sweeper doc id == auth uid
    final byId = await f.collection('sweepers').doc(user.uid).get();
    if (byId.exists) {
      final data = byId.data();
      final n = data?['name']?.toString().trim();
      if (n != null && n.isNotEmpty) return n;
    }

    // fallback: by email
    if ((user.email ?? '').isNotEmpty) {
      final q = await f
          .collection('sweepers')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final n = q.docs.first.data()['name']?.toString().trim();
        if (n != null && n.isNotEmpty) return n;
      }
    }

    // last fallback
    return user.displayName ?? user.email?.split('@').first ?? 'Sweeper';
  }

  Future<void> _autoFillCompany() async {
    setState(() => _resolvingCompany = true);
    final result = await _getCompanyFromBin(_binIdController.text);
    if (mounted) {
      _resolvedCompanyId = result['id'];
      _companyNameController.text = result['name'] ?? '';
      setState(() => _resolvingCompany = false);
    }
  }
  // --------------------------------------------------------------------------

  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // basic form check
    if (_selectedIssue == null ||
        _binIdController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // Ensure we have companyId + companyName from bin (even if user didn't tap refresh)
    String? companyName = _companyNameController.text.trim().isEmpty
        ? null
        : _companyNameController.text.trim();

    if (_resolvedCompanyId == null || companyName == null) {
      final res = await _getCompanyFromBin(_binIdController.text);
      _resolvedCompanyId ??= res['id'];
      companyName ??= res['name'];
    }

    if (_resolvedCompanyId == null ||
        (companyName == null || companyName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bin not found or Company not assigned.")),
      );
      return;
    }

    final sweeperName = await _resolveSweeperName();

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        // 🔗 Use BOTH id + name so CompanyDashboard can filter reliably
        'companyId': _resolvedCompanyId, // ✅ critical for dashboard
        'companyName': companyName, // nice for display / fallback

        // who + what
        'sweeperId': user.uid,
        'sweeperName': sweeperName ?? 'Sweeper',
        'binId': _binIdController.text.trim(),
        'issue': _selectedIssue, // CompanyDashboard reads 'issue'
        'issueType': _selectedIssue, // (compat / duplicates ok)
        'description': _descriptionController.text.trim(),

        // when
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Report Submitted'),
          content: const Text('Your report has been successfully submitted.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _binIdController.clear();
                _descriptionController.clear();
                _companyNameController.clear();
                _resolvedCompanyId = null;
                setState(() => _selectedIssue = null);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            const Text('Report Issue', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown('Issue Type'),
            const SizedBox(height: 16),
            _buildTextField('Bin ID', controller: _binIdController),
            const SizedBox(height: 16),

            // Company name: read-only, auto-filled from bin
            const Text('Company Name', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _companyNameController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Auto-filled from Bin',
                suffixIcon: IconButton(
                  icon: _resolvingCompany
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  onPressed: _resolvingCompany ? null : _autoFillCompany,
                  tooltip: 'Resolve from Bin',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildTextField('Description',
                controller: _descriptionController, maxLines: 4),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2082DD),
                ),
                child: const Text('Submit Report',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedIssue,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'Overflow', child: Text('Overflow')),
            DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (value) => setState(() => _selectedIssue = value),
        ),
      ],
    );
  }

  Widget _buildTextField(String label,
      {int maxLines = 1, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}