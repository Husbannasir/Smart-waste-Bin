// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'company_dashboard.dart';
// import 'company_bins.dart';
// import 'company_sweeper.dart';

// class CompanyHomePage extends StatefulWidget {
//   const CompanyHomePage({super.key});

//   @override
//   State<CompanyHomePage> createState() => _CompanyHomePageState();
// }

// class _CompanyHomePageState extends State<CompanyHomePage> {
//   int _selectedIndex = 0;
//   String? companyId;
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadCompanyId();
//   }

//   Future<void> _loadCompanyId() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       try {
//         // 🔹 Try to fetch company doc from Firestore
//         final doc = await FirebaseFirestore.instance
//             .collection('companies')
//             .doc(user.uid) // assumes company UID = auth UID
//             .get();

//         if (doc.exists) {
//           setState(() {
//             companyId = doc.data()?['companyId'] ?? user.uid;
//             _loading = false;
//           });
//         } else {
//           // fallback to UID if no companyId field
//           setState(() {
//             companyId = user.uid;
//             _loading = false;
//           });
//         }
//       } catch (e) {
//         debugPrint("Error fetching companyId: $e");
//         setState(() {
//           companyId = user.uid;
//           _loading = false;
//         });
//       }
//     } else {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }

//   Widget _getTab(int index) {
//     if (_loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (companyId == null) {
//       return const Center(child: Text("Error: Company ID not found"));
//     }

//     switch (index) {
//       case 0:
//         return CompanyDashboard(companyId: companyId!);
//       case 1:
//         return const CompanyBinsScreen();
//       case 2:
//         return const CompanySweeper();
//       default:
//         return CompanyDashboard(companyId: companyId!);
//     }
//   }

//   void _onItemTapped(int index) async {
//     if (index == 0 && _selectedIndex == 0) {
//       final shouldLogout = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Log Out'),
//           content: const Text('Do you want to log out?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text('Log Out'),
//             ),
//           ],
//         ),
//       );

//       if (shouldLogout ?? false) {
//         await FirebaseAuth.instance.signOut();
//       }
//     } else {
//       setState(() {
//         _selectedIndex = index;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _getTab(_selectedIndex),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         items: const [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.dashboard), label: 'Dashboard'),
//           BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Bins'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.cleaning_services), label: 'Sweepers'),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'company_dashboard.dart';
// import 'company_bins.dart' as bins;
// import 'company_sweeper.dart' as sweepers;

// class CompanyHomePage extends StatefulWidget {
//   const CompanyHomePage({super.key});

//   @override
//   State<CompanyHomePage> createState() => _CompanyHomePageState();
// }

// class _CompanyHomePageState extends State<CompanyHomePage> {
//   int _selectedIndex = 0;
//   String? companyId;
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadCompanyId();
//   }

//   Future<void> _loadCompanyId() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       try {
//         final doc = await FirebaseFirestore.instance
//             .collection('companies')
//             .doc(user.uid)
//             .get();

//         if (doc.exists) {
//           setState(() {
//             companyId = doc.data()?['companyId'] ?? user.uid;
//             _loading = false;
//           });
//         } else {
//           setState(() {
//             companyId = user.uid;
//             _loading = false;
//           });
//         }
//       } catch (e) {
//         debugPrint("Error fetching companyId: $e");
//         setState(() {
//           companyId = user.uid;
//           _loading = false;
//         });
//       }
//     } else {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }

//   Widget _getTab(int index) {
//     if (_loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (companyId == null) {
//       return const Center(child: Text("Error: Company ID not found"));
//     }

//     switch (index) {
//       case 0:
//         return CompanyDashboard();
//       case 1:
//         return const bins.CompanyBinsScreen();
//       case 2:
//         return const sweepers.CompanySweeper();
//       default:
//         return CompanyDashboard();
//     }
//   }

//   void _onItemTapped(int index) async {
//     if (index == 0 && _selectedIndex == 0) {
//       final shouldLogout = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Log Out'),
//           content: const Text('Do you want to log out?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text('Log Out'),
//             ),
//           ],
//         ),
//       );

//       if (shouldLogout ?? false) {
//         await FirebaseAuth.instance.signOut();
//       }
//     } else {
//       setState(() {
//         _selectedIndex = index;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _getTab(_selectedIndex),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         items: const [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.dashboard), label: 'Dashboard'),
//           BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Bins'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.cleaning_services), label: 'Sweepers'),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'company_dashboard.dart';
import 'company_bins.dart' as bins;
import 'company_sweeper.dart' as sweepers;

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) async {
    if (index == 0 && _selectedIndex == 0) {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Do you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Log Out'),
            ),
          ],
        ),
      );

      if (shouldLogout ?? false) {
        await FirebaseAuth.instance.signOut();
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _getTab(int index) {
    switch (index) {
      case 0:
        return const CompanyDashboard(); // no companyId needed
      case 1:
        return const bins.CompanyBinsScreen();
      case 2:
        return const sweepers.CompanySweeper();
      default:
        return const CompanyDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getTab(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Bins'),
          BottomNavigationBarItem(
              icon: Icon(Icons.cleaning_services), label: 'Sweepers'),
        ],
      ),
    );
  }
}

