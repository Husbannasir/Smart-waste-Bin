import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/Intro.dart';
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

  // 🔹 Titles for the glassy header
  final List<String> _titles = [
    "Company Dashboard",
    "Bin Management",
    "Sweeper Staff"
  ];

  @override
  Widget build(BuildContext context) {
    // Screens list inside build
    final List<Widget> _widgetOptions = [
      const CompanyDashboard(),
      const bins.CompanyBinsScreen(),
      const sweepers.CompanySweeper(),
    ];

    return Scaffold(
      extendBody: true, // 🔹 Taake content Nav bar ke peeche nazar aaye
      body: Stack(
        children: [
          // 1. Fresh Background Gradient
          // CompanyHomePage ke build method mein ye wala Container update karein:
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(
                      255, 150, 220, 238), // 🔹 Deep Indigo (Professional)
                  Color.fromARGB(255, 86, 145, 233), // 🔹 Royal Blue
                  Color.fromARGB(255, 58, 167, 250), // 🔹 Navy Blue
                ],
              ),
            ),
          ),
          // 2. Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildCenteredGlassHeader(), // 🔹 Centered Header (No Arrow)
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _widgetOptions,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildModernAnimatedNav(), // 🔹 Stylish Glassy Nav
    );
  }

  // 🔹 CENTERED GLASSY HEADER (No Back Arrow)
  Widget _buildCenteredGlassHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Center(
              child: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: Color(0xFF00796B),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 MODERN FLOATING ANIMATED NAV BAR
  Widget _buildModernAnimatedNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2979FF).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, "Home"),
              _buildNavItem(1, Icons.delete_sweep_rounded, "Bins"),
              _buildNavItem(2, Icons.people_alt_rounded, "Staff"),
              _buildLogoutItem(), // 🔹 Separate Logout on Tap
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
            scale: isSelected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2979FF)
                  : Colors.blueGrey.shade300,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: isSelected ? 12 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 SPECIAL LOGOUT ITEM
  // 🔹 UPDATED LOGOUT ITEM (With Proper Navigation)
  Widget _buildLogoutItem() {
    return GestureDetector(
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A237E), // Deep Blue Theme match
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white24),
            ),
            title: const Text('Log Out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text(
                'Are you sure you want to exit the Company Portal?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldLogout ?? false) {
          // 1. Firebase se logout
          await FirebaseAuth.instance.signOut();

          // 2. Navigation Fix: App ko Intro screen par bhejna aur purani sari memory clear karna
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const IntroScreen()),
              (route) => false, // 🔹 Ye line sab back-stack khatam kar degi
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 26),
      ),
    );
  }
}
