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

  late List<Widget> _widgetOptions;

  @override
  Widget build(BuildContext context) {
    // Initialize screens dynamically with userName
    _widgetOptions = <Widget>[
      SweeperDashboardScreen(), // Dashboard will fetch userName inside itself
      const SweeperAlertsScreen(),
      const SweeperReportsScreen(),
      const SweeperProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text(
          _selectedIndex == 0
              ? "Tasks"
              : _selectedIndex == 1
                  ? "Alerts"
                  : _selectedIndex == 2
                      ? "Reports"
                      : "Profile",
          style: const TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Task'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
