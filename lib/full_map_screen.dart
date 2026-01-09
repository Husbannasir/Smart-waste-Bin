import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firebase_fs;

class FullMapScreen extends StatefulWidget {
  final bool isPickerMode; // 🔹 Add Bin se true, Dashboard se false

  const FullMapScreen({super.key, this.isPickerMode = false});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  late MapController controller;
  final firebase_fs.FirebaseFirestore _firestore =
      firebase_fs.FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    controller = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isPickerMode ? "Select Bin Location" : "Bins Live Status"),
        backgroundColor: const Color(0xFF22B5FE),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isPickerMode)
            IconButton(
              icon:
                  const Icon(Icons.check_circle, size: 32, color: Colors.white),
              onPressed: () async {
                // 🔹 Behtar tareeqa coordinates lene ka
                GeoPoint point = await controller.centerMap;
                if (context.mounted) Navigator.pop(context, point);
              },
            ),
        ],
      ),
      body: StreamBuilder<firebase_fs.QuerySnapshot>(
        stream: _firestore.collection("bins").snapshots(),
        builder: (context, snapshot) {
          // 🔹 Markers prepare karna
          List<GeoPoint> fullBins = [];
          List<GeoPoint> activeBins = [];

          if (!widget.isPickerMode && snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['lat'] != null && data['lng'] != null) {
                GeoPoint p = GeoPoint(
                  latitude: (data['lat'] as num).toDouble(),
                  longitude: (data['lng'] as num).toDouble(),
                );
                if (data['status'].toString().toLowerCase() == 'full') {
                  fullBins.add(p);
                } else {
                  activeBins.add(p);
                }
              }
            }
          }

          return Stack(
            children: [
              OSMFlutter(
                controller: controller,
                osmOption: OSMOption(
                  zoomOption: const ZoomOption(initZoom: 14),
                  staticPoints: widget.isPickerMode
                      ? []
                      : [
                          StaticPositionGeoPoint(
                            "full",
                            const MarkerIcon(
                                icon: Icon(Icons.delete,
                                    color: Colors.red, size: 60)),
                            fullBins,
                          ),
                          StaticPositionGeoPoint(
                            "active",
                            const MarkerIcon(
                                icon: Icon(Icons.delete,
                                    color: Colors.green, size: 60)),
                            activeBins,
                          ),
                        ],
                  userLocationMarker: UserLocationMaker(
                    personMarker: const MarkerIcon(
                      icon: Icon(Icons.person_pin_circle,
                          color: Colors.blue, size: 48),
                    ),
                    directionArrowMarker:
                        const MarkerIcon(icon: Icon(Icons.navigation)),
                  ),
                ),
              ),

              // 🔹 Red Crosshair (Sirf Picker Mode mein)
              if (widget.isPickerMode)
                IgnorePointer(
                  // 🔹 Taake map scrolling mein masla na ho
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 35),
                      child: Icon(Icons.location_on,
                          color: Colors.red.withOpacity(0.9), size: 60),
                    ),
                  ),
                ),

              // 🔹 Stylish Instruction Overlay
              if (widget.isPickerMode)
                Positioned(
                  bottom: 40,
                  left: 25,
                  right: 25,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      color: Colors.black87,
                      child: const Text(
                        "Map ko move karein aur Red Marker ko bin ki jagah par set karke upar ✔ dabayein",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
