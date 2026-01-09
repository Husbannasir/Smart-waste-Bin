import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/Admin_dashboard.dart';
import 'package:my_app/admin_login_page.dart';
import 'Sweeper_login.dart';
import 'Company_login.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  User? _currentUser;
  bool _isAdmin = false;
  bool _loading = true;

  // Animations for background moving circles
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    _checkUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _isAdmin = true;
          _currentUser = user;
        });
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF22B5FE))),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Base Gradient
          Container(color: const Color(0xFFF3F7FF)),

          // 2. Animated Background Blobs (Wow Factor)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildAnimatedBlob(
                    color: const Color(0xFF22B5FE).withOpacity(0.4),
                    top: 100 * _controller.value,
                    left: 50 * _controller.value,
                    size: 200,
                  ),
                  _buildAnimatedBlob(
                    color: const Color(0xFFED5B5B).withOpacity(0.3),
                    bottom: 150 * _controller.value,
                    right: -20 * _controller.value,
                    size: 250,
                  ),
                  _buildAnimatedBlob(
                    color: const Color(0xFF1DE9B6).withOpacity(0.3),
                    top: 400 * (1 - _controller.value),
                    left: -30,
                    size: 180,
                  ),
                ],
              );
            },
          ),

          // 3. Main Content with Glassmorphism
          SafeArea(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Logo Section with subtle animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(scale: value, child: child),
                          );
                        },
                        child: const Icon(Icons.auto_delete_rounded,
                            size: 80, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Smart Waste',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D3142),
                            letterSpacing: -1),
                      ),
                      const Text(
                        'Select your portal to continue',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),

                      // Glass Cards
                      _buildGlassyPortalCard(
                        title: 'Admin Dashboard',
                        subtitle: 'Control & Monitor System',
                        icon: Icons.admin_panel_settings_rounded,
                        accentColor: const Color(0xFF22B5FE),
                        onPressed: () {
                          if (_currentUser != null && _isAdmin) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminDashboardScreen()));
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminLoginPage()));
                          }
                        },
                      ),
                      _buildGlassyPortalCard(
                        title: 'Sweeper Portal',
                        subtitle: 'Manage Routes & Jobs',
                        icon: Icons.cleaning_services_rounded,
                        accentColor: const Color(0xFFED5B5B),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SweeperLoginScreen())),
                      ),
                      _buildGlassyPortalCard(
                        title: 'Company Portal',
                        subtitle: 'Analyze Reports & Data',
                        icon: Icons.business_rounded,
                        accentColor: const Color(0xFF2D3142),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CompanyLoginScreen())),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Helper to build animated background circles
  Widget _buildAnimatedBlob(
      {required Color color,
      double? top,
      double? left,
      double? right,
      double? bottom,
      required double size}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  // 🔹 Modular Glassy Card
  Widget _buildGlassyPortalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2), // Transparency
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: accentColor, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142))),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: accentColor.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
