import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 🔹 MODELS (Fixed)
class BinModel {
  final String id, location, status, assignedCompany, assignedSweeper;
  BinModel(
      {required this.id,
      required this.location,
      required this.status,
      required this.assignedCompany,
      required this.assignedSweeper});

  factory BinModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BinModel(
      id: (data['id'] ?? 'N/A').toString(),
      location: (data['location'] ?? 'Unknown').toString(),
      status: (data['status'] ?? 'Empty').toString(),
      assignedCompany: (data['assignedCompanyId'] ?? '').toString(),
      assignedSweeper: (data['assignedSweeperId'] ?? '').toString(),
    );
  }
}

class SweeperModel {
  final String id, name;
  SweeperModel({required this.id, required this.name});
  factory SweeperModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SweeperModel(
        id: doc.id, name: (data['name'] ?? 'Unnamed').toString());
  }
}

class CompanyModel {
  final String id, name;
  CompanyModel({required this.id, required this.name});
  factory CompanyModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CompanyModel(
        id: doc.id, name: (data['name'] ?? 'No Name').toString());
  }
}

class ReportsScreenFirestore extends StatefulWidget {
  const ReportsScreenFirestore({super.key});
  @override
  State<ReportsScreenFirestore> createState() => _ReportsScreenFirestoreState();
}

class _ReportsScreenFirestoreState extends State<ReportsScreenFirestore> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  String? selectedCompany, selectedSweeper, searchQuery = '';

  Stream<List<BinModel>> get binsStream => _fs
      .collection('bins')
      .snapshots()
      .map((snap) => snap.docs.map((d) => BinModel.fromDoc(d)).toList());
  Stream<List<SweeperModel>> get sweepersStream => _fs
      .collection('sweepers')
      .snapshots()
      .map((snap) => snap.docs.map((d) => SweeperModel.fromDoc(d)).toList());
  Stream<List<CompanyModel>> get companiesStream => _fs
      .collection('companies')
      .snapshots()
      .map((snap) => snap.docs.map((d) => CompanyModel.fromDoc(d)).toList());

  List<BinModel> _applyFilters(List<BinModel> allBins) {
    var result = allBins;
    if (selectedCompany != null && selectedCompany!.isNotEmpty) {
      result =
          result.where((b) => b.assignedCompany == selectedCompany).toList();
    }
    if (selectedSweeper != null && selectedSweeper!.isNotEmpty) {
      result =
          result.where((b) => b.assignedSweeper == selectedSweeper).toList();
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      result = result
          .where((b) =>
              b.id.toLowerCase().contains(searchQuery!.toLowerCase()) ||
              b.location.toLowerCase().contains(searchQuery!.toLowerCase()))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildGlassyHeader(), // 🔹 Arrow khatam kar diya
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildGlassyFilters(),
                      const SizedBox(height: 25),
                      _buildStatsRow(),
                      const SizedBox(height: 25),
                      _buildGlassyTable(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassyHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          "Admin Reports",
          style: TextStyle(
              color: Color(0xFF2D3142),
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildGlassyFilters() {
    return _glassyWrapper(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildCompanyDropdown()),
              const SizedBox(width: 10),
              Expanded(child: _buildSweeperDropdown()),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            decoration: InputDecoration(
              hintText: "Search ID or Location...",
              prefixIcon:
                  const Icon(Icons.search, size: 20, color: Color(0xFF22B5FE)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.3),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    return StreamBuilder<List<CompanyModel>>(
      stream: companiesStream,
      builder: (context, snap) {
        final items = snap.data ?? [];
        return DropdownButtonFormField<String>(
          value: selectedCompany,
          decoration: const InputDecoration(labelText: "Company"),
          items: [
            const DropdownMenuItem(value: null, child: Text("All")),
            ...items
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          ],
          onChanged: (v) => setState(() => selectedCompany = v),
        );
      },
    );
  }

  Widget _buildSweeperDropdown() {
    return StreamBuilder<List<SweeperModel>>(
      stream: sweepersStream,
      builder: (context, snap) {
        final items = snap.data ?? [];
        return DropdownButtonFormField<String>(
          value: selectedSweeper,
          decoration: const InputDecoration(labelText: "Sweeper"),
          items: [
            const DropdownMenuItem(value: null, child: Text("All")),
            ...items
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
          ],
          onChanged: (v) => setState(() => selectedSweeper = v),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<List<BinModel>>(
      stream: binsStream,
      builder: (context, snap) {
        final bins = snap.data ?? [];
        return Row(
          children: [
            Expanded(
                child: _buildGlassyCard(
                    "Total Bins", bins.length.toString(), Colors.blueAccent)),
            const SizedBox(width: 15),
            Expanded(
                child: _buildGlassyCard(
                    "Full Bins",
                    bins.where((b) => b.status == 'Full').length.toString(),
                    Colors.redAccent)),
          ],
        );
      },
    );
  }

  Widget _buildGlassyTable() {
    return StreamBuilder<List<BinModel>>(
      stream: binsStream,
      builder: (context, snap) {
        final visibleBins = _applyFilters(snap.data ?? []);
        return _glassyWrapper(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              columns: const [
                DataColumn(label: Text('Bin ID')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Location')),
              ],
              rows: visibleBins
                  .map((b) => DataRow(cells: [
                        DataCell(Text(b.id)),
                        DataCell(_statusChip(b.status)),
                        DataCell(Text(b.location))
                      ]))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _glassyWrapper({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassyCard(String title, String val, Color col) {
    return _glassyWrapper(
      child: Column(
        children: [
          Text(val,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: col)),
          Text(title,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    bool isFull = status.toLowerCase() == 'full';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: (isFull ? Colors.red : Colors.green).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(
              color: isFull ? Colors.red : Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
