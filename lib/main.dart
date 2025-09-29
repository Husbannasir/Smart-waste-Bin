import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screens
import 'firebase_options.dart';
import 'Intro.dart';
import 'Admin_dashboard.dart';
import 'Company_dashboard.dart';
import 'sweeper_dashboard.dart';

/// AuthWrapper: decides where to go (Intro/Login OR Dashboard)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  /// Get role for logged-in user
  Future<String?> _getUserRole(User user) async {
    final uid = user.uid;

    try {
      // ✅ 1. Admin check
      final adminDoc =
          await FirebaseFirestore.instance.collection("admins").doc(uid).get();
      if (adminDoc.exists) return "admin";

      // ✅ 2. Company check
      final companyDoc = await FirebaseFirestore.instance
          .collection("companies")
          .doc(uid)
          .get();
      if (companyDoc.exists) return "company";

      // ✅ 3. Sweeper check
      final sweeperDoc = await FirebaseFirestore.instance
          .collection("sweepers")
          .doc(uid)
          .get();
      if (sweeperDoc.exists) return "sweeper";
    } catch (e) {
      debugPrint("❌ Error fetching role: $e");
    }

    return null; // no role found
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Still loading Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. User not logged in → Intro/Login screen
        if (!snapshot.hasData || snapshot.data == null) {
          return const IntroScreen();
        }

        // 3. User is logged in → fetch role
        return FutureBuilder<String?>(
          future: _getUserRole(snapshot.data!),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnapshot.hasData) {
              switch (roleSnapshot.data) {
                case "admin":
                  return const AdminDashboardScreen();

                case "company":
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("companies")
                        .where("email",
                            isEqualTo:
                                snapshot.data!.email) // ✅ match logged-in user
                        .limit(1)
                        .get(),
                    builder: (context, companySnap) {
                      if (!companySnap.hasData) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (companySnap.data!.docs.isEmpty) {
                        return const Scaffold(
                          body: Center(child: Text("❌ Company not found")),
                        );
                      }

                      final companyDoc = companySnap.data!.docs.first;
                      final companyId = companyDoc["companyId"];

                      return CompanyDashboard();
                    },
                  );

                case "sweeper":
                  return const SweeperDashboardScreen();
              }
            }

            // 4. No role found → unauthorized
            return const Scaffold(
              body: Center(child: Text("Unauthorized or Role not assigned")),
            );
          },
        );
      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Waste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthWrapper(), // ✅ wrapper to decide screen
    );
  }
}
