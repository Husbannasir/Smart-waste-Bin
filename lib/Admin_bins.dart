import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    as firebase_fs; // 🔹 FIX: Firestore ko 'firebase_fs' ka naam de diya
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart'; // 🔹 Ab yahan ka GeoPoint default rahega
import 'Admin_dashboard.dart';
import 'full_map_screen.dart';

enum BinStatus { Empty, Full, Damaged }

class AdminBinsScreen extends StatefulWidget {
  const AdminBinsScreen({super.key});

  @override
  State<AdminBinsScreen> createState() => _AdminBinsScreenState();
}

class _AdminBinsScreenState extends State<AdminBinsScreen> {
  // 🔹 Firestore instance with alias
  final firebase_fs.FirebaseFirestore _firestore =
      firebase_fs.FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Color(0xFF2D3142)),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AdminDashboardScreen()),
                          );
                        },
                      ),
                      const Expanded(
                        child: Center(
                          child: Text("Manage Bins",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3142))),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bin Inventory",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Click cards to see details",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddBinDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("Add Bin"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22B5FE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<
                        firebase_fs.QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore.collection("bins").snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF22B5FE)));
                        }
                        final bins = snapshot.data!.docs;
                        if (bins.isEmpty)
                          return const Center(child: Text("No bins found."));
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: bins.length,
                          itemBuilder: (context, index) {
                            return _buildBinCard(
                                bins[index].id, bins[index].data());
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBinDialog(BuildContext context) {
    final idController = TextEditingController();
    final locationController = TextEditingController();
    final capacityController = TextEditingController();

    // 🔹 Coordinate Controllers (Fixed)
    final latController = TextEditingController();
    final lngController = TextEditingController();

    String? selectedCompanyDocId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("Add New Bin",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: idController,
                    decoration: const InputDecoration(
                        labelText: "Bin ID", prefixIcon: Icon(Icons.qr_code))),
                TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                        labelText: "Area Name",
                        prefixIcon: Icon(Icons.map_outlined))),
                TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Capacity (L)",
                        prefixIcon: Icon(Icons.waves))),
                const SizedBox(height: 15),

                // 🔹 NEW: Map Picker Row
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: latController,
                            decoration: const InputDecoration(labelText: "Lat"),
                            readOnly: true, // User type nahi kar sakega
                            style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: lngController,
                            decoration: const InputDecoration(labelText: "Lng"),
                            readOnly: true, // User type nahi kar sakega
                            style: const TextStyle(fontSize: 12))),
                    IconButton(
                      icon: const Icon(Icons.pin_drop,
                          color: Color(0xFF22B5FE), size: 30),
                      onPressed: () async {
                        // 🔹 Open FullMapScreen in Picker Mode
                        final pickedPoint = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const FullMapScreen(isPickerMode: true)),
                        );

                        if (pickedPoint != null && pickedPoint is GeoPoint) {
                          dialogSetState(() {
                            latController.text =
                                pickedPoint.latitude.toString();
                            lngController.text =
                                pickedPoint.longitude.toString();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                StreamBuilder<firebase_fs.QuerySnapshot>(
                  stream: _firestore.collection("companies").snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    return DropdownButtonFormField<String>(
                      hint: const Text("Select Company"),
                      items: snap.data!.docs
                          .map((d) => DropdownMenuItem(
                              value: d.id, child: Text(d['name'] ?? 'No Name')))
                          .toList(),
                      onChanged: (v) => selectedCompanyDocId = v,
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22B5FE),
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (idController.text.isEmpty || latController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please select a location on map")));
                  return;
                }

                await _firestore.collection("bins").add({
                  "id": idController.text.trim(),
                  "location": locationController.text.trim(),
                  "capacity": int.tryParse(capacityController.text) ?? 0,
                  "status": "Empty",
                  "lat": double.tryParse(latController.text),
                  "lng": double.tryParse(lngController.text),
                  "assignedCompanyId": selectedCompanyDocId,
                  "assignedSweeperId": null,
                  "createdBy": user?.uid,
                  "updatedAt": firebase_fs.FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save Bin"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBinCard(String docId, Map<String, dynamic> binData) {
    String statusStr = binData["status"] ?? "Empty";
    Color statusColor = statusStr == "Full"
        ? Colors.red
        : (statusStr == "Damaged" ? Colors.orange : Colors.green);

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showBinDetails(binData),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF22B5FE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.delete_sweep_rounded,
                  color: Color(0xFF22B5FE)),
            ),
            title: Text("Bin #${binData["id"] ?? "N/A"}",
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text("📍 ${binData["location"] ?? 'Unknown'}",
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(statusStr,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "Assign") _showAssignDialog(context, docId);
                if (value == "Delete")
                  _firestore.collection("bins").doc(docId).delete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: "Assign", child: Text("Assign")),
                const PopupMenuItem(
                    value: "Delete",
                    child: Text("Delete", style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBinDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Bin Info",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompanyNameLine(companyId: data["assignedCompanyId"]),
            const SizedBox(height: 10),
            _SweeperNameLine(sweeperId: data["assignedSweeperId"]),
            const Divider(height: 30),
            Text("Location: ${data['location']}"),
            Text("Coordinates: ${data['lat']}, ${data['lng']}"),
            Text("Capacity: ${data['capacity']} Liters"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, String binDocId) async {
    String? selectedSweeperId;
    final binDoc = await _firestore.collection("bins").doc(binDocId).get();
    final binData = binDoc.data() as Map<String, dynamic>;
    final String? currentCompanyId = binData["assignedCompanyId"];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Assign Sweeper",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: FutureBuilder<
            List<firebase_fs.DocumentSnapshot<Map<String, dynamic>>>>(
          future: _getAvailableSweepers(currentCompanyId),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final availableSweepers = snapshot.data!;
            return DropdownButtonFormField<String>(
              hint: const Text("Select a Sweeper"),
              items: availableSweepers
                  .map((doc) => DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc.data()!["name"] ?? "Unnamed")))
                  .toList(),
              onChanged: (value) => selectedSweeperId = value,
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22B5FE)),
            onPressed: () async {
              if (selectedSweeperId != null) {
                await _firestore
                    .collection("bins")
                    .doc(binDocId)
                    .update({"assignedSweeperId": selectedSweeperId});
                if (context.mounted) Navigator.pop(context);
              }
            },
            child:
                const Text("Assign Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<List<firebase_fs.DocumentSnapshot<Map<String, dynamic>>>>
      _getAvailableSweepers(String? companyId) async {
    final sweeperSnapshot = await _firestore.collection("sweepers").get();
    return sweeperSnapshot.docs.toList();
  }
}

// 🔹 Re-using your helper components
class _CompanyNameLine extends StatelessWidget {
  final String? companyId;
  const _CompanyNameLine({required this.companyId});
  @override
  Widget build(BuildContext context) {
    if (companyId == null)
      return const Text("🏢 Company: Not Assigned",
          style: TextStyle(color: Colors.redAccent));
    return FutureBuilder<firebase_fs.DocumentSnapshot>(
      future: firebase_fs.FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Text("Loading...");
        return Text("🏢 Company: ${snap.data?['name'] ?? 'Unknown'}",
            style: const TextStyle(fontWeight: FontWeight.bold));
      },
    );
  }
}

class _SweeperNameLine extends StatelessWidget {
  final String? sweeperId;
  const _SweeperNameLine({required this.sweeperId});
  @override
  Widget build(BuildContext context) {
    if (sweeperId == null)
      return const Text("🧹 Sweeper: Not Assigned",
          style: TextStyle(color: Colors.redAccent));
    return FutureBuilder<firebase_fs.DocumentSnapshot>(
      future: firebase_fs.FirebaseFirestore.instance
          .collection('sweepers')
          .doc(sweeperId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Text("Loading...");
        return Text("🧹 Sweeper: ${snap.data?['name'] ?? 'Unknown'}",
            style: const TextStyle(fontWeight: FontWeight.bold));
      },
    );
  }
}
