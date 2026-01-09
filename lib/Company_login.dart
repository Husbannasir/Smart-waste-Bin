import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_app/Company_pass.dart';
import 'package:my_app/Company_home.dart';
import 'package:my_app/Company_signup.dart';

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  CompanyLoginScreenState createState() => CompanyLoginScreenState();
}

class CompanyLoginScreenState extends State<CompanyLoginScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyIdController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _loginCompany() async {
    // 🔹 Showing a quick loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2979FF))),
    );

    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot doc = await _firestore
          .collection("companies")
          .doc(userCred.user!.uid)
          .get();

      Navigator.pop(context); // Remove loading

      if (doc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CompanyHomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Company record not found in database"),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Login failed: ${e.toString()}"),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Modern Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD), // Very light blue
                  Color(0xFFBBDEFB), // Soft sky blue
                  Color(0xFFE1F5FE),
                ],
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // 🔹 Glassy Header Card
                    _buildGlassHeader(),
                    const SizedBox(height: 30),

                    // 🔹 Main Login Form Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Company ID'),
                              _buildGlassField(_companyIdController,
                                  Icons.business_rounded, 'Enter ID'),
                              const SizedBox(height: 18),

                              _buildLabel('Official Email'),
                              _buildGlassField(_emailController,
                                  Icons.email_outlined, 'name@company.com'),
                              const SizedBox(height: 18),

                              _buildLabel('Password'),
                              _buildGlassPasswordField(),
                              const SizedBox(height: 12),

                              _buildRememberForgotRow(),
                              const SizedBox(height: 30),

                              // 🔹 MODERN LOGIN BUTTON
                              _buildLoginButton(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    _buildSignupPrompt(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader() {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2979FF).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2979FF).withOpacity(0.3)),
          ),
          child: const Icon(Icons.domain_rounded,
              size: 40, color: Color(0xFF2979FF)),
        ),
        const SizedBox(height: 15),
        const Text(
          'Company Portal',
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
              letterSpacing: 1),
        ),
        const Text('Manage your operations efficiently',
            style: TextStyle(color: Colors.black54, fontSize: 14)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
    );
  }

  Widget _buildGlassField(
      TextEditingController controller, IconData icon, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF2979FF), size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGlassPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Color(0xFF2979FF), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.black45,
              size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        hintText: '••••••••',
        filled: true,
        fillColor: Colors.white.withOpacity(0.4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildRememberForgotRow() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _rememberMe,
            activeColor: const Color(0xFF2979FF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) => setState(() => _rememberMe = val ?? false),
          ),
        ),
        const SizedBox(width: 8),
        const Text('Remember me',
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CompanyForgotPasswordScreen())),
          child: const Text('Forgot Password?',
              style: TextStyle(
                  color: Color(0xFF2979FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _loginCompany,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2979FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          shadowColor: const Color(0xFF2979FF).withOpacity(0.4),
        ),
        child: const Text('Sign In to Portal',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSignupPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("New company? ", style: TextStyle(color: Colors.black54)),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CompanySignUpScreen())),
          child: const Text('Register Now',
              style: TextStyle(
                  color: Color(0xFF2979FF), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
