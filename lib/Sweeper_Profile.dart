import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/Intro.dart';

class SweeperProfileScreen extends StatelessWidget {
  const SweeperProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("⚠ No user logged in")));
    }

    final userName = user.displayName ?? user.email?.split('@').first ?? "User";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sweeper Profile',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      // ✅ Count bins this sweeper cleaned (we rely on lastCleaned/lastCleanedBy)
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("bins")
            .where("lastCleanedBy", isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

          int todayCount = 0;
          int weekCount = 0;

          for (final d in docs) {
            final ts = d.data()['lastCleaned'];
            if (ts is Timestamp) {
              final cleanedAt = ts.toDate();
              if (!cleanedAt.isBefore(startOfToday)) todayCount++;
              if (!cleanedAt.isBefore(startOfWeek)) weekCount++;
            }
          }

          final efficiency =
              weekCount == 0 ? 0.0 : (todayCount / weekCount * 100.0);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                      radius: 50, child: Icon(Icons.person, size: 50)),
                  const SizedBox(height: 16),
                  Text(userName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(todayCount.toString(), "Today"),
                      _buildStatCard(weekCount.toString(), "This Week"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEfficiencyCard("${efficiency.toStringAsFixed(0)}%"),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const IntroScreen()),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Log Out',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildStatCard(String value, String label) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  static Widget _buildEfficiencyCard(String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF19CD55))),
            const SizedBox(width: 8),
            const Text('Efficiency Rating',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}