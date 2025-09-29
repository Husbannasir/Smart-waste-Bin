import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum BinStatus { Empty, Full, Damaged }

class AdminBinsScreen extends StatefulWidget {
  const AdminBinsScreen({super.key});

  @override
  State<AdminBinsScreen> createState() => _AdminBinsScreenState();
}

class _AdminBinsScreenState extends State<AdminBinsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Bins")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showAddBinDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Add New Bin"),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore.collection("bins").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bins = snapshot.data!.docs;
                  if (bins.isEmpty) {
                    return const Center(child: Text("No bins found."));
                  }
                  return ListView.builder(
                    itemCount: bins.length,
                    itemBuilder: (context, index) {
                      final binData = bins[index].data();
                      return _buildBinCard(bins[index].id, binData);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBinCard(String docId, Map<String, dynamic> binData) {
    final BinStatus status = BinStatus.values.firstWhere(
      (e) => e.toString().split('.').last == (binData["status"] ?? "Empty"),
      orElse: () => BinStatus.Empty,
    );

    final String? companyId = binData["assignedCompanyId"] as String?;
    final String? sweeperId = binData["assignedSweeperId"] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          (binData["id"] ?? "No ID").toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Location: ${binData["location"] ?? ''}"),
            Text("Capacity: ${binData["capacity"] ?? 0} liters"),
            _CompanyNameLine(companyId: companyId),
            _SweeperNameLine(sweeperId: sweeperId),
            const SizedBox(height: 5),
            _buildStatusChip(status),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "Assign") {
              _showAssignDialog(context, docId);
            } else if (value == "Delete") {
              _firestore.collection("bins").doc(docId).delete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: "Assign", child: Text("Assign Sweeper")),
            PopupMenuItem(value: "Delete", child: Text("Delete")),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BinStatus status) {
    Color color;
    String text;
    switch (status) {
      case BinStatus.Empty:
        color = Colors.green;
        text = "Empty";
        break;
      case BinStatus.Full:
        color = Colors.red;
        text = "Full";
        break;
      case BinStatus.Damaged:
        color = Colors.grey;
        text = "Damaged";
        break;
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  void _showAddBinDialog(BuildContext context) {
    final idController = TextEditingController();
    final locationController = TextEditingController();
    final capacityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        BinStatus selectedStatus = BinStatus.Empty;

        // yahan hum company ka DOC ID store karenge
        String? selectedCompanyDocId;
        String? selectedCompanyName;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text("Add New Bin"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: "Bin ID"),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: "Location"),
                    ),
                    TextField(
                      controller: capacityController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: "Capacity (liters)"),
                    ),
                    DropdownButtonFormField<BinStatus>(
                      value: selectedStatus,
                      items: BinStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toString().split('.').last),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          dialogSetState(() => selectedStatus = v);
                        }
                      },
                      decoration: const InputDecoration(labelText: "Status"),
                    ),

                    // 🔽 Companies dropdown -> value = company DOC ID
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore.collection("companies").snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(),
                          );
                        }
                        final companies = snapshot.data!.docs;

                        // agar selected id list me nahi, to value null rakhain
                        final safeValue =
                            companies.any((d) => d.id == selectedCompanyDocId)
                                ? selectedCompanyDocId
                                : null;

                        return DropdownButtonFormField<String>(
                          value: safeValue,
                          hint: const Text("Assign to Company (Optional)"),
                          items: companies.map((doc) {
                            final m = doc.data();
                            final display =
                                (m["name"] ?? m["companyName"] ?? "Unnamed")
                                    .toString();
                            return DropdownMenuItem(
                              // ✅ YAHI SABSE IMPORTANT: value = doc.id
                              value: doc.id,
                              child: Text(display),
                            );
                          }).toList(),
                          onChanged: (v) {
                            dialogSetState(() {
                              selectedCompanyDocId = v;
                              if (v != null) {
                                final picked = companies
                                    .firstWhere((d) => d.id == v)
                                    .data();
                                selectedCompanyName = (picked["name"] ??
                                        picked["companyName"] ??
                                        "")
                                    .toString()
                                    .trim();
                              } else {
                                selectedCompanyName = null;
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _firestore.collection("bins").add({
                      "id": idController.text.trim(),
                      "location": locationController.text.trim(),
                      "capacity": int.tryParse(capacityController.text) ?? 0,
                      "status": selectedStatus.toString().split('.').last,

                      // ✅ SINGLE SOURCE OF TRUTH
                      "assignedCompanyId":
                          selectedCompanyDocId, // <-- DOC ID save hoti hai
                      "assignedSweeperId": null, // sweeper baad me assign hoga

                      // (optional) sirf UI display ke liye
                      "assignedCompanyName": selectedCompanyName,

                      "createdBy": user?.uid,
                      "updatedAt": FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Bin added successfully")),
                    );
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Assign Sweeper (ID only)
  void _showAssignDialog(BuildContext context, String binDocId) async {
    String? selectedSweeperId;

    final binDoc = await _firestore.collection("bins").doc(binDocId).get();
    final binData = binDoc.data() as Map<String, dynamic>;
    final String? currentCompanyId = binData["assignedCompanyId"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Assign Sweeper"),
        content: FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
          future: _getAvailableSweepers(currentCompanyId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final availableSweepers = snapshot.data!;
            if (availableSweepers.isEmpty) {
              return const Text("⚠ No available sweepers for this company.");
            }
            return DropdownButtonFormField<String>(
              value: selectedSweeperId,
              hint: const Text("Select a Sweeper"),
              items: availableSweepers.map((doc) {
                final sweeper = doc.data()!;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text((sweeper["name"] ?? "Unnamed").toString()),
                );
              }).toList(),
              onChanged: (value) => selectedSweeperId = value,
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedSweeperId != null) {
                await _firestore.collection("bins").doc(binDocId).update({
                  "assignedSweeperId": selectedSweeperId,
                  "updatedAt": FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Sweeper Assigned")),
                  );
                }
              }
            },
            child: const Text("Assign"),
          ),
        ],
      ),
    );
  }

  // Helper: limit sweepers to same company or unassigned
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _getAvailableSweepers(
      String? companyId) async {
    final sweeperSnapshot = await _firestore.collection("sweepers").get();

    final binSnapshot = await _firestore.collection("bins").get();

    final Map<String, Set<String>> sweeperCompanyMap = {};
    for (var bin in binSnapshot.docs) {
      final data = bin.data();
      final sid = data["assignedSweeperId"] as String?;
      final cid = data["assignedCompanyId"] as String?;
      if (sid != null && cid != null) {
        (sweeperCompanyMap[sid] ??= {}).add(cid);
      }
    }

    return sweeperSnapshot.docs.where((doc) {
      final sid = doc.id;
      final companiesAssigned = sweeperCompanyMap[sid] ?? {};
      return companiesAssigned.isEmpty ||
          (companyId != null &&
              companiesAssigned.length == 1 &&
              companiesAssigned.contains(companyId));
    }).toList();
  }
}

/// Displays "Company: <name>" from companyId (reads companies/<id>)
class _CompanyNameLine extends StatelessWidget {
  final String? companyId;
  const _CompanyNameLine({required this.companyId});

  @override
  Widget build(BuildContext context) {
    if (companyId == null || companyId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get(),
      builder: (context, snap) {
        // snap.data is a property (can be null)
        final map = snap.data?.data(); // Map<String, dynamic>?
        final name =
            (map?['name'] ?? map?['companyName'] ?? 'Unknown').toString();
        return Text("Company: $name");
      },
    );
  }
}

/// Displays "Assigned Sweeper: <name>" from sweeperId
class _SweeperNameLine extends StatelessWidget {
  final String? sweeperId;
  const _SweeperNameLine({required this.sweeperId});

  @override
  Widget build(BuildContext context) {
    if (sweeperId == null || sweeperId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('sweepers')
          .doc(sweeperId)
          .get(),
      builder: (context, snap) {
        final map = snap.data?.data();
        final name = (map?['name'] ?? 'Unknown').toString();
        return Text("Assigned Sweeper: $name");
      },
    );
  }
}