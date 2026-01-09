import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Intro.dart';

class SweeperProfileScreen extends StatelessWidget {
  const SweeperProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("⚠ No user logged in"));
    }

    final userName = user.displayName ?? user.email?.split('@').first ?? "User";

    return Material(
      color: Colors.transparent, // Parent Panel handle karega background
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("bins")
            .where("lastCleanedBy", isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BFA5)));
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

          final efficiency = weekCount == 0
              ? 0.0
              : (todayCount / (weekCount / 7) * 10); // Simple logic for rating
          final rating = efficiency > 100 ? 100 : efficiency;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 🔹 PROFILE AVATAR SECTION
                _buildProfileHeader(userName, user.email ?? ""),

                const SizedBox(height: 30),

                // 🔹 STATS CARDS (Today & Week)
                Row(
                  children: [
                    _buildGlassStatCard("Today", todayCount.toString(),
                        Icons.today_rounded, Colors.blueAccent),
                    const SizedBox(width: 15),
                    _buildGlassStatCard("Weekly", weekCount.toString(),
                        Icons.bar_chart_rounded, const Color(0xFF00BFA5)),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔹 EFFICIENCY RATING CARD
                _buildEfficiencyGlassCard(rating.toStringAsFixed(0)),

                const SizedBox(height: 20),

                // 🔹 ADDITIONAL INFO BOX (Modern Touch)
                _buildInfoSection(docs),

                const SizedBox(height: 40),

                // 🔹 LOGOUT BUTTON
                _buildLogoutButton(context),

                const SizedBox(height: 120), // Bottom Nav space
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔹 Profile Header with Glass Effect
  Widget _buildProfileHeader(String name, String email) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
              child: const CircleAvatar(
                radius: 55,
                backgroundColor: Color(0xFFE0F2F1),
                child: Icon(Icons.person_rounded,
                    size: 65, color: Color(0xFF00796B)),
              ),
            ),
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF00BFA5),
              child: Icon(Icons.verified_user, size: 18, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(name,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00796B))),
        Text(email,
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }

  // 🔹 Glass Stat Card
  Widget _buildGlassStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 15),
                Text(value,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Efficiency Glass Card
  Widget _buildEfficiencyGlassCard(String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(25),
            border:
                Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            children: [
              CircularProgressIndicator(
                value: double.parse(value) / 100,
                backgroundColor: Colors.white.withOpacity(0.3),
                color: const Color(0xFF00BFA5),
                strokeWidth: 8,
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$value%",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00796B))),
                  const Text("Overall Efficiency",
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Modern Info Section
  // 🔹 Is section ko SweeperProfileScreen ke build method mein use karein
  Widget _buildInfoSection(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    // Admin ne jo bins is sweeper ko diye hain, un mein se pehla area nikalna
    String assignedArea = "No Area Assigned Yet";

    if (docs.isNotEmpty) {
      assignedArea = docs.first.data()['location'] ?? "Location Not Set";
      // 👆 Yeh 'location' wahi field hai jo Admin ne bin assign karte waqt dali hogi
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const _InfoRow(Icons.access_time_filled, "Shift",
                  "Morning (08:00 AM - 04:00 PM)"),
              const Divider(color: Colors.white24),

              // 🔹 REAL-TIME AREA FROM ADMIN
              _InfoRow(Icons.location_city, "Assigned Area", assignedArea),

              const Divider(color: Colors.white24),
              const _InfoRow(Icons.stars_rounded, "Rank", "Senior Sweeper"),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Logout Button
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ).child(
        child: InkWell(
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const IntroScreen()),
                (route) => false);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded),
              SizedBox(width: 10),
              Text("Log Out",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Info Rows
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoRow(this.icon, this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00796B), size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      fontWeight: FontWeight.bold)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔹 Extension to fix button style as I used shorthand
extension ButtonExt on ButtonStyle {
  Widget child({required Widget child}) =>
      ElevatedButton(onPressed: null, style: this, child: child);
}
