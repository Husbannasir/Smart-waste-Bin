import 'dart:ui';
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
  String? _resolvedCompanyId;

  // ------------------ logic functions preserved ------------------
  Future<Map<String, String?>> _getCompanyFromBin(String binId) async {
    final Map<String, String?> out = {'id': null, 'name': null};
    final id = binId.trim();
    if (id.isEmpty) return out;
    final f = FirebaseFirestore.instance;
    final q =
        await f.collection('bins').where('id', isEqualTo: id).limit(1).get();
    if (q.docs.isEmpty) return out;
    final m = q.docs.first.data();
    final cid = (m['assignedCompanyId'] ?? '').toString().trim();
    final cname = ((m['assignedCompanyName'] ?? m['companyName']) ?? '')
        .toString()
        .trim();
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

  Future<void> _autoFillCompany() async {
    setState(() => _resolvingCompany = true);
    final result = await _getCompanyFromBin(_binIdController.text);
    if (mounted) {
      _resolvedCompanyId = result['id'];
      _companyNameController.text = result['name'] ?? '';
      setState(() => _resolvingCompany = false);
    }
  }

  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_selectedIssue == null ||
        _binIdController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please fill all fields"),
          behavior: SnackBarBehavior.floating));
      return;
    }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Bin not found or Company not assigned."),
          behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'companyId': _resolvedCompanyId,
        'companyName': companyName,
        'sweeperId': user.uid,
        'sweeperName': user.displayName ?? 'Sweeper',
        'binId': _binIdController.text.trim(),
        'issue': _selectedIssue,
        'description': _descriptionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Success! ✅'),
        content: const Text('Your report has been submitted to the company.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _binIdController.clear();
              _descriptionController.clear();
              _companyNameController.clear();
              setState(() => _selectedIssue = null);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF00BFA5))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Report Issue',
            style: TextStyle(
                color: Color(0xFF00796B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // 🔹 FIX: Back arrow ko permanent khatam kar diya
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // 🔹 GLASSY FORM CONTAINER
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Issue Type'),
                      _buildGlassDropdown(),
                      const SizedBox(height: 20),

                      _buildLabel('Bin ID'),
                      _buildGlassTextField(
                          controller: _binIdController, hint: 'e.g. 103'),
                      const SizedBox(height: 20),

                      _buildLabel('Company Name'),
                      _buildCompanyField(),
                      const SizedBox(height: 20),

                      _buildLabel('Short Description'),
                      _buildGlassTextField(
                          controller: _descriptionController,
                          hint: 'Describe the problem...',
                          maxLines: 4),

                      const SizedBox(height: 30),

                      // 🔹 MODERN SUBMIT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                            shadowColor:
                                const Color(0xFF00BFA5).withOpacity(0.3),
                          ),
                          child: const Text('Submit Report',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120), // 🔹 Space for Bottom Navigation Bar
          ],
        ),
      ),
    );
  }

  // UI Helpers (Labels, Fields, Dropdown) remain same as before
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00796B))),
    );
  }

  Widget _buildGlassTextField(
      {required TextEditingController controller,
      String? hint,
      int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF00BFA5))),
      ),
    );
  }

  Widget _buildGlassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedIssue,
          isExpanded: true,
          hint: const Text('Select Issue'),
          dropdownColor: const Color(0xFFE0F7FA),
          items: ['Overflow', 'Damaged', 'Other'].map((String val) {
            return DropdownMenuItem<String>(value: val, child: Text(val));
          }).toList(),
          onChanged: (value) => setState(() => _selectedIssue = value),
        ),
      ),
    );
  }

  Widget _buildCompanyField() {
    return TextField(
      controller: _companyNameController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Tap refresh to auto-fill',
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        suffixIcon: IconButton(
          icon: _resolvingCompany
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF00BFA5)))
              : const Icon(Icons.refresh_rounded, color: Color(0xFF00BFA5)),
          onPressed: _resolvingCompany ? null : _autoFillCompany,
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
      ),
    );
  }
}
