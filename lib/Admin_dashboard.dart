import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/Admin_bins.dart';
import 'package:my_app/Admin_sweeper.dart';
import 'package:my_app/Admin_companies.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    as firebase_fs; // 🔹 Aliased for GeoPoint conflict
import 'package:my_app/Intro.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_app/Admin_reports.dart';
import 'package:my_app/full_map_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final firebase_fs.FirebaseFirestore _firestore =
      firebase_fs.FirebaseFirestore.instance;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 DASHBOARD HOME BODY
    Widget dashboardBody = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 25),
          const Text(
            'Hello Admin 👋',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: Color(0xFF2D3142)),
          ),
          const Text('Real-time status of your smart bins',
              style: TextStyle(fontSize: 16, color: Colors.black45)),
          const SizedBox(height: 35),

          // 🔹 STATS GRID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: StreamBuilder<firebase_fs.QuerySnapshot>(
              stream: _firestore.collection("bins").snapshots(),
              builder: (context, binSnapshot) {
                int totalBins = binSnapshot.data?.docs.length ?? 0;
                int fullBins = binSnapshot.data?.docs
                        .where((doc) =>
                            doc['status'].toString().toLowerCase() == 'full')
                        .length ??
                    0;

                return StreamBuilder<firebase_fs.QuerySnapshot>(
                  stream: _firestore.collection("sweepers").snapshots(),
                  builder: (context, sweeperSnapshot) {
                    int sweepers = sweeperSnapshot.data?.docs.length ?? 0;

                    return StreamBuilder<firebase_fs.QuerySnapshot>(
                      stream: _firestore.collection("companies").snapshots(),
                      builder: (context, companySnapshot) {
                        int companies = companySnapshot.data?.docs.length ?? 0;

                        return GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.4,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildGlassyCard(
                                "Total Bins",
                                totalBins.toString(),
                                Icons.delete_rounded,
                                const Color(0xFF22B5FE),
                                1),
                            _buildGlassyCard("Full Bins", fullBins.toString(),
                                Icons.warning_rounded, Colors.orangeAccent, 1),
                            _buildGlassyCard(
                                "Sweepers",
                                sweepers.toString(),
                                Icons.cleaning_services_rounded,
                                Colors.greenAccent,
                                2),
                            _buildGlassyCard("Companies", companies.toString(),
                                Icons.business_rounded, Colors.indigoAccent, 3),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Live Tracking Map',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF2D3142))),
            ),
          ),
          const SizedBox(height: 15),

          // 🔹 LIVE BINS MAP FIXED (WITH CLICK & MARKERS)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 450,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: StreamBuilder<firebase_fs.QuerySnapshot>(
                  stream: _firestore.collection("bins").snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<GeoPoint> fullBinsPoints = [];
                    List<GeoPoint> activeBinsPoints = [];

                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['lat'] != null && data['lng'] != null) {
                          GeoPoint point = GeoPoint(
                            latitude: (data['lat'] as num).toDouble(),
                            longitude: (data['lng'] as num).toDouble(),
                          );

                          if (data['status'].toString().toLowerCase() ==
                                  'full' ||
                              data['status'].toString().toLowerCase() ==
                                  'overflow') {
                            fullBinsPoints.add(point);
                          } else {
                            activeBinsPoints.add(point);
                          }
                        }
                      }
                    }

                    return Stack(
                      children: [
                        OSMFlutter(
                          controller: _mapController,
                          osmOption: OSMOption(
                            zoomOption: const ZoomOption(initZoom: 12),
                            staticPoints: [
                              StaticPositionGeoPoint(
                                "full",
                                const MarkerIcon(
                                    icon: Icon(Icons.delete,
                                        color: Colors.red, size: 65)),
                                fullBinsPoints,
                              ),
                              StaticPositionGeoPoint(
                                "active",
                                const MarkerIcon(
                                    icon: Icon(Icons.delete,
                                        color: Colors.green, size: 65)),
                                activeBinsPoints,
                              ),
                            ],
                            userLocationMarker: UserLocationMaker(
                              personMarker: const MarkerIcon(
                                  icon: Icon(Icons.admin_panel_settings,
                                      color: Colors.blue, size: 48)),
                              directionArrowMarker: const MarkerIcon(
                                  icon: Icon(Icons.location_on,
                                      color: Colors.blue)),
                            ),
                          ),
                        ),
                        // 🔹 Transparent Click Layer to Open Full Map
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const FullMapScreen()));
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 150),
        ],
      ),
    );

    final List<Widget> screens = [
      dashboardBody,
      const AdminBinsScreen(),
      const AdminSweepersScreen(),
      const AdminCompaniesScreen(),
      const ReportsScreenFirestore(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 190, 241, 241), Color(0xFFCFDEF3)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color.fromARGB(255, 185, 230, 248),
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text("Admin Panel",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 26)),
            actions: [_buildProfileMenu(context), const SizedBox(width: 15)],
          ),
          body: screens[_selectedIndex],
          bottomNavigationBar: _buildBottomNav(),
          extendBody: true,
        ),
      ),
    );
  }

  // 🔹 STATS CARD HELPER
  Widget _buildGlassyCard(
      String title, String value, IconData icon, Color color, int index) {
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.7), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 5),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142))),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 STYLISH ANIMATED BOTTOM NAV BAR
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 25),
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF22B5FE).withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10))
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, 'Home'),
              _buildNavItem(1, Icons.delete_outline, 'Bins'),
              _buildNavItem(2, Icons.people_outline, 'Sweepers'),
              _buildNavItem(3, Icons.business_outlined, 'Company'),
              _buildNavItem(4, Icons.bar_chart_rounded, 'Reports'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(icon,
                color:
                    isSelected ? const Color(0xFF22B5FE) : Colors.grey.shade500,
                size: isSelected ? 30 : 26),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: isSelected ? 4 : 0,
            decoration: const BoxDecoration(
                color: Color(0xFF22B5FE), shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.account_circle_rounded,
          size: 36, color: Color(0xFF2D3142)),
      onSelected: (value) async {
        if (value == 1) {
          await FirebaseAuth.instance.signOut();
          if (mounted)
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const IntroScreen()));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
            enabled: false,
            child: Text(FirebaseAuth.instance.currentUser?.email ?? "Admin",
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold))),
        const PopupMenuDivider(),
        const PopupMenuItem(
            value: 1,
            child: Row(children: [
              Icon(Icons.logout, color: Colors.red, size: 22),
              SizedBox(width: 10),
              Text("Logout")
            ])),
      ],
    );
  }
}
