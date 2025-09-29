// // import 'package:flutter/material.dart';
// // import 'package:my_app/Admin_bins.dart';
// // import 'package:my_app/Admin_sweeper.dart';
// // import 'package:my_app/Admin_companies.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:my_app/Intro.dart';
// // import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:my_app/reports_screen.dart';

// // class AdminDashboardScreen extends StatefulWidget {
// //   const AdminDashboardScreen({super.key});

// //   @override
// //   State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
// // }

// // class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
// //   int _selectedIndex = 0;

// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// //   late final MapController _mapController;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _mapController = MapController.withUserPosition(
// //         trackUserLocation: const UserTrackingOption());
// //     _checkPermission();
// //   }

// //   Future<void> _checkPermission() async {
// //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     if (!serviceEnabled) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Location services are disabled.")),
// //       );
// //       return;
// //     }

// //     LocationPermission permission = await Geolocator.checkPermission();
// //     if (permission == LocationPermission.denied) {
// //       permission = await Geolocator.requestPermission();
// //       if (permission == LocationPermission.denied) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Location permission denied.")),
// //         );
// //         return;
// //       }
// //     }

// //     if (permission == LocationPermission.deniedForever) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text(
// //               "Location permission permanently denied. Enable it from settings."),
// //         ),
// //       );
// //       return;
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     Widget dashboardBody = SingleChildScrollView(
// //       child: Padding(
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text(
// //               'Admin Dashboard',
// //               style: TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 22,
// //               ),
// //             ),
// //             const SizedBox(height: 2),
// //             const Text(
// //               'Welcome to the Admin Dashboard',
// //               style: TextStyle(fontSize: 15, color: Colors.black54),
// //             ),
// //             const SizedBox(height: 18),

// //             // 🔹 Summary Cards
// //             StreamBuilder<QuerySnapshot>(
// //               stream: _firestore.collection("bins").snapshots(),
// //               builder: (context, binSnapshot) {
// //                 int totalBins = binSnapshot.data?.docs.length ?? 0;
// //                 int fullBins = binSnapshot.data?.docs
// //                         .where((doc) => doc['status'] == 'full')
// //                         .length ??
// //                     0;
// //                 return Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     _dashboardCard(totalBins.toString(), 'Total Bins'),
// //                     _dashboardCard(fullBins.toString(), 'Full Bins'),
// //                   ],
// //                 );
// //               },
// //             ),
// //             const SizedBox(height: 12),
// //             StreamBuilder<QuerySnapshot>(
// //               stream: _firestore.collection("sweepers").snapshots(),
// //               builder: (context, sweeperSnapshot) {
// //                 int sweepers = sweeperSnapshot.data?.docs.length ?? 0;
// //                 return StreamBuilder<QuerySnapshot>(
// //                   stream: _firestore.collection("companies").snapshots(),
// //                   builder: (context, companySnapshot) {
// //                     int companies = companySnapshot.data?.docs.length ?? 0;
// //                     return Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         _dashboardCard(sweepers.toString(), 'Sweepers'),
// //                         _dashboardCard(companies.toString(), 'Companies'),
// //                       ],
// //                     );
// //                   },
// //                 );
// //               },
// //             ),

// //             const SizedBox(height: 20),
// //             const Text(
// //               'Latest Alerts',
// //               style: TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //               ),
// //             ),
// //             const SizedBox(height: 8),
// //             _alertCard('BIN-001 (Main Street) - Overflow detected'),
// //             const SizedBox(height: 6),
// //             _alertCard('BIN-003 (Downtown) - Bin full, needs collection'),

// //             const SizedBox(height: 18),
// //             const Text(
// //               'Real-time Tracking',
// //               style: TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //               ),
// //             ),
// //             const SizedBox(height: 10),

// //             // 🔹 OSM Map
// //             Container(
// //               height: 250,
// //               decoration: BoxDecoration(
// //                 borderRadius: BorderRadius.circular(16),
// //                 color: Colors.grey[300],
// //               ),
// //               child: ClipRRect(
// //                 borderRadius: BorderRadius.circular(16),
// //                 child: OSMFlutter(
// //                   controller: _mapController,
// //                   osmOption: const OSMOption(
// //                     zoomOption: ZoomOption(
// //                       initZoom: 12,
// //                       minZoomLevel: 3,
// //                       maxZoomLevel: 18,
// //                       stepZoom: 1.0,
// //                     ),
// //                     userTrackingOption: UserTrackingOption(
// //                       enableTracking: true,
// //                       unFollowUser: false,
// //                     ),
// //                     showDefaultInfoWindow: true,
// //                     isPicker: false,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );

// //     final List<Widget> screens = [
// //       dashboardBody,
// //       const AdminBinsScreen(),
// //       const AdminSweepersScreen(),
// //       const AdminCompaniesScreen(),
// //       const ReportsScreen(), // Ab yeh Reports tab functional hai
// //     ];
// //     return WillPopScope(
// //       onWillPop: () async {
// //         if (_selectedIndex != 0) {
// //           setState(() => _selectedIndex = 0);
// //           return false;
// //         }
// //         return true;
// //       },
// //       child: Scaffold(
// //         backgroundColor: const Color(0xFFF6FAFF),
// //         appBar: AppBar(
// //           title: const Text("Admin Dashboard"),
// //           actions: [
// //             PopupMenuButton<int>(
// //               icon: const Icon(Icons.account_circle, size: 28),
// //               onSelected: (value) async {
// //                 if (value == 1) {
// //                   await FirebaseAuth.instance.signOut();
// //                   Navigator.pushReplacement(
// //                     context,
// //                     MaterialPageRoute(builder: (context) => IntroScreen()),
// //                   );
// //                 }
// //               },
// //               itemBuilder: (context) => [
// //                 PopupMenuItem(
// //                   value: 0,
// //                   enabled: false,
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         FirebaseAuth.instance.currentUser?.displayName ??
// //                             "Admin",
// //                         style: const TextStyle(
// //                           fontWeight: FontWeight.bold,
// //                           fontSize: 16,
// //                         ),
// //                       ),
// //                       Text(
// //                         FirebaseAuth.instance.currentUser?.email ?? "",
// //                         style: const TextStyle(
// //                           fontSize: 14,
// //                           color: Colors.grey,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 const PopupMenuDivider(),
// //                 const PopupMenuItem(
// //                   value: 1,
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.logout, color: Colors.red),
// //                       SizedBox(width: 8),
// //                       Text("Logout"),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             )
// //           ],
// //         ),
// //         body: screens[_selectedIndex],
// //         bottomNavigationBar: BottomNavigationBar(
// //           backgroundColor: const Color(0xFFE8EAF6),
// //           type: BottomNavigationBarType.fixed,
// //           selectedItemColor: const Color.fromARGB(255, 46, 109, 228),
// //           unselectedItemColor: const Color.fromARGB(255, 88, 87, 87),
// //           showUnselectedLabels: true,
// //           iconSize: 20,
// //           selectedLabelStyle: const TextStyle(fontSize: 11),
// //           unselectedLabelStyle: const TextStyle(fontSize: 11),
// //           currentIndex: _selectedIndex,
// //           onTap: (index) {
// //             setState(() => _selectedIndex = index);
// //           },
// //           items: const [
// //             BottomNavigationBarItem(
// //               icon: Icon(Icons.dashboard),
// //               label: 'Dashboard',
// //             ),
// //             BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Bins'),
// //             BottomNavigationBarItem(
// //               icon: Icon(Icons.cleaning_services),
// //               label: 'Sweepers',
// //             ),
// //             BottomNavigationBarItem(
// //               icon: Icon(Icons.business),
// //               label: 'Companies',
// //             ),
// //             BottomNavigationBarItem(
// //               icon: Icon(Icons.bar_chart),
// //               label: 'Reports',
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   static Widget _dashboardCard(String value, String label) {
// //     return Container(
// //       width: 150,
// //       height: 70,
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(14),
// //         boxShadow: const [
// //           BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
// //         ],
// //       ),
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Text(
// //             value,
// //             style: const TextStyle(
// //                 fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
// //           ),
// //           const SizedBox(height: 4),
// //           Text(
// //             label,
// //             style: const TextStyle(fontSize: 14, color: Colors.black54),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   static Widget _alertCard(String text) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFFFD6D6),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(color: const Color(0xFFFF6B6B)),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(Icons.warning, color: Color(0xFFFF6B6B)),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Text(
// //               text,
// //               style: const TextStyle(
// //                   color: Color(0xFFB00020), fontWeight: FontWeight.bold),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:my_app/Admin_bins.dart';
// import 'package:my_app/Admin_sweeper.dart';
// import 'package:my_app/Admin_companies.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:my_app/Intro.dart';
// import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:my_app/Adminreports_screen.dart'; // ✅ Correct import

// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({super.key});

//   @override
//   State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
// }

// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   int _selectedIndex = 0;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late final MapController _mapController;

//   @override
//   void initState() {
//     super.initState();
//     _mapController = MapController.withUserPosition(
//       trackUserLocation: const UserTrackingOption(),
//     );
//     _checkPermission();
//   }

//   Future<void> _checkPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Location services are disabled.")),
//       );
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Location permission denied.")),
//         );
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//               "Location permission permanently denied. Enable it from settings."),
//         ),
//       );
//       return;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget dashboardBody = SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Admin Dashboard',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 22,
//               ),
//             ),
//             const SizedBox(height: 2),
//             const Text(
//               'Welcome to the Admin Dashboard',
//               style: TextStyle(fontSize: 15, color: Colors.black54),
//             ),
//             const SizedBox(height: 18),

//             // 🔹 Summary Cards
//             StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection("bins").snapshots(),
//               builder: (context, binSnapshot) {
//                 int totalBins = binSnapshot.data?.docs.length ?? 0;
//                 int fullBins = binSnapshot.data?.docs
//                         .where((doc) => doc['status'] == 'full')
//                         .length ??
//                     0;
//                 return Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     _dashboardCard(totalBins.toString(), 'Total Bins'),
//                     _dashboardCard(fullBins.toString(), 'Full Bins'),
//                   ],
//                 );
//               },
//             ),
//             const SizedBox(height: 12),
//             StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection("sweepers").snapshots(),
//               builder: (context, sweeperSnapshot) {
//                 int sweepers = sweeperSnapshot.data?.docs.length ?? 0;
//                 return StreamBuilder<QuerySnapshot>(
//                   stream: _firestore.collection("companies").snapshots(),
//                   builder: (context, companySnapshot) {
//                     int companies = companySnapshot.data?.docs.length ?? 0;
//                     return Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         _dashboardCard(sweepers.toString(), 'Sweepers'),
//                         _dashboardCard(companies.toString(), 'Companies'),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),

//             const SizedBox(height: 20),
//             const Text(
//               'Latest Alerts',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 8),
//             _alertCard('BIN-001 (Main Street) - Overflow detected'),
//             const SizedBox(height: 6),
//             _alertCard('BIN-003 (Downtown) - Bin full, needs collection'),

//             const SizedBox(height: 18),
//             const Text(
//               'Real-time Tracking',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 10),

//             // 🔹 OSM Map
//             Container(
//               height: 250,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 color: Colors.grey[300],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: OSMFlutter(
//                   controller: _mapController,
//                   osmOption: const OSMOption(
//                     zoomOption: ZoomOption(
//                       initZoom: 12,
//                       minZoomLevel: 3,
//                       maxZoomLevel: 18,
//                       stepZoom: 1.0,
//                     ),
//                     userTrackingOption: UserTrackingOption(
//                       enableTracking: true,
//                       unFollowUser: false,
//                     ),
//                     showDefaultInfoWindow: true,
//                     isPicker: false,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );

//     final List<Widget> screens = [
//       dashboardBody,
//       const AdminBinsScreen(),
//       const AdminSweepersScreen(),
//       const AdminCompaniesScreen(),
//       const AdminReportsScreen(), // ✅ Fixed ReportsScreen
//     ];

//     return WillPopScope(
//       onWillPop: () async {
//         if (_selectedIndex != 0) {
//           setState(() => _selectedIndex = 0);
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF6FAFF),
//         appBar: AppBar(
//           title: const Text("Admin Dashboard"),
//           actions: [
//             PopupMenuButton<int>(
//               icon: const Icon(Icons.account_circle, size: 28),
//               onSelected: (value) async {
//                 if (value == 1) {
//                   await FirebaseAuth.instance.signOut();
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(builder: (context) => IntroScreen()),
//                   );
//                 }
//               },
//               itemBuilder: (context) => [
//                 PopupMenuItem(
//                   value: 0,
//                   enabled: false,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         FirebaseAuth.instance.currentUser?.displayName ?? "Admin",
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Text(
//                         FirebaseAuth.instance.currentUser?.email ?? "",
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuDivider(),
//                 const PopupMenuItem(
//                   value: 1,
//                   child: Row(
//                     children: [
//                       Icon(Icons.logout, color: Colors.red),
//                       SizedBox(width: 8),
//                       Text("Logout"),
//                     ],
//                   ),
//                 ),
//               ],
//             )
//           ],
//         ),
//         body: screens[_selectedIndex],
//         bottomNavigationBar: BottomNavigationBar(
//           backgroundColor: const Color(0xFFE8EAF6),
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: const Color.fromARGB(255, 46, 109, 228),
//           unselectedItemColor: const Color.fromARGB(255, 88, 87, 87),
//           showUnselectedLabels: true,
//           iconSize: 20,
//           selectedLabelStyle: const TextStyle(fontSize: 11),
//           unselectedLabelStyle: const TextStyle(fontSize: 11),
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() => _selectedIndex = index);
//           },
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.dashboard),
//               label: 'Dashboard',
//             ),
//             BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Bins'),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.cleaning_services),
//               label: 'Sweepers',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.business),
//               label: 'Companies',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.bar_chart),
//               label: 'Reports',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   static Widget _dashboardCard(String value, String label) {
//     return Container(
//       width: 150,
//       height: 70,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: const [
//           BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             value,
//             style: const TextStyle(
//                 fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 14, color: Colors.black54),
//           ),
//         ],
//       ),
//     );
//   }

//   static Widget _alertCard(String text) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFD6D6),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFFFF6B6B)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.warning, color: Color(0xFFFF6B6B)),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                   color: Color(0xFFB00020), fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:my_app/Admin_bins.dart';
import 'package:my_app/Admin_sweeper.dart';
import 'package:my_app/Admin_companies.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/Intro.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_app/Adminreports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController.withUserPosition(
        trackUserLocation: const UserTrackingOption());
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Location permission permanently denied. Enable it from settings."),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget dashboardBody = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Welcome to the Admin Dashboard',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 18),

            // 🔹 Summary Cards
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection("bins").snapshots(),
              builder: (context, binSnapshot) {
                int totalBins = binSnapshot.data?.docs.length ?? 0;
                int fullBins = binSnapshot.data?.docs
                        .where((doc) => doc['status'] == 'full')
                        .length ??
                    0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _dashboardCard(totalBins.toString(), 'Total Bins'),
                    _dashboardCard(fullBins.toString(), 'Full Bins'),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection("sweepers").snapshots(),
              builder: (context, sweeperSnapshot) {
                int sweepers = sweeperSnapshot.data?.docs.length ?? 0;
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection("companies").snapshots(),
                  builder: (context, companySnapshot) {
                    int companies = companySnapshot.data?.docs.length ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _dashboardCard(sweepers.toString(), 'Sweepers'),
                        _dashboardCard(companies.toString(), 'Companies'),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 18),
            const Text(
              'Real-time Tracking',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 OSM Map
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: OSMFlutter(
                  controller: _mapController,
                  osmOption: const OSMOption(
                    zoomOption: ZoomOption(
                      initZoom: 12,
                      minZoomLevel: 3,
                      maxZoomLevel: 18,
                      stepZoom: 1.0,
                    ),
                    userTrackingOption: UserTrackingOption(
                      enableTracking: true,
                      unFollowUser: false,
                    ),
                    showDefaultInfoWindow: true,
                    isPicker: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final List<Widget> screens = [
      dashboardBody,
      const AdminBinsScreen(),
      const AdminSweepersScreen(),
      const AdminCompaniesScreen(),
      const ReportsScreen(), // ✅ yahan sahi naam
    ];
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFF),
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.account_circle, size: 28),
              onSelected: (value) async {
                if (value == 1) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => IntroScreen()),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0,
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FirebaseAuth.instance.currentUser?.displayName ??
                            "Admin",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Logout"),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
        body: screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFE8EAF6),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color.fromARGB(255, 46, 109, 228),
          unselectedItemColor: const Color.fromARGB(255, 88, 87, 87),
          showUnselectedLabels: true,
          iconSize: 20,
          selectedLabelStyle: const TextStyle(fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Bins'),
            BottomNavigationBarItem(
              icon: Icon(Icons.cleaning_services),
              label: 'Sweepers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: 'Companies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _dashboardCard(String value, String label) {
    return Container(
      width: 150,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  static Widget _alertCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD6D6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF6B6B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Color(0xFFFF6B6B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Color(0xFFB00020), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
