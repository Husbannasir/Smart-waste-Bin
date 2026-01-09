import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sweeper_dashboard.dart';
import 'sweeper_alerts.dart';
import 'sweeper_reports.dart';
import 'sweeper_profile.dart';

class SweeperPanel extends StatefulWidget {
  const SweeperPanel({super.key});

  @override
  State<SweeperPanel> createState() => _SweeperPanelState();
}

class _SweeperPanelState extends State<SweeperPanel> {
  int _selectedIndex = 0;
  late String userName;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userName = user?.displayName ?? user?.email?.split('@')[0] ?? "User";
  }

  // Titles list for the glassy header
  final List<String> _titles = ["Tasks", "Alerts", "Reports", "Profile"];

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = [
      const SweeperDashboardScreen(),
      const SweeperAlertsScreen(),
      const SweeperReportsScreen(),
      const SweeperProfileScreen(),
    ];

    return Scaffold(
      extendBody: false, // 🔹 Content Nav Bar ke peeche flow karega
      body: Stack(
        children: [
          // 1. Fixed Background Gradient (Pure theme ke liye)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F7FA), Color(0xFFE1F5FE)],
              ),
            ),
          ),

          // 2. Main Body Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildCenteredGlassHeader(), // 🔹 Stylish Header
                Expanded(
                  child: IndexedStack(
                    // 🔹 Screen switch par data save rakhta hai
                    index: _selectedIndex,
                    children: _widgetOptions,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildModernAnimatedNav(), // 🔹 Stylish Nav Bar
    );
  }

  // 🔹 STYLISH CENTERED GLASS HEADER
  Widget _buildCenteredGlassHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
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
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.task_alt_rounded),
              _buildNavItem(1, Icons.notifications_active_rounded),
              _buildNavItem(2, Icons.analytics_rounded),
              _buildNavItem(3, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
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
            curve: Curves.easeOutBack, // 🔹 Smooth spring effect
            child: Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF00BFA5)
                  : Colors.blueGrey.shade300,
              size: 28,
            ),
          ),
          const SizedBox(height: 5),
          // Floating Dot Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: isSelected ? 15 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
