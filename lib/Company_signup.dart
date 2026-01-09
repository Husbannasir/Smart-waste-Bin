import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Company_login.dart';

class CompanySignUpScreen extends StatefulWidget {
  const CompanySignUpScreen({super.key});

  @override
  State<CompanySignUpScreen> createState() => _CompanySignUpScreenState();
}

class _CompanySignUpScreenState extends State<CompanySignUpScreen> {
  bool _obscurePassword = true;

  // Controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerCompany() async {
    // 🔹 Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2972FE))),
    );

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      await _firestore.collection("companies").doc(user!.uid).set({
        "name": _companyNameController.text.trim(),
        "email": _emailController.text.trim(),
        "companyId": _companyIdController.text.trim(),
        "phone": _phoneController.text.trim(),
        "bins": 0,
        "sweepers": 0,
        "timestamp": FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // Remove loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Company registered successfully!"),
            behavior: SnackBarBehavior.floating),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompanyLoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message ?? "Registration failed"),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F7FF),
                  Color(0xFFE1F5FE),
                  Color(0xFFE3F2FD)
                ],
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBackButton(),
                  const SizedBox(height: 20),

                  // 🔹 Header Section
                  const Text('Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0))),
                  const Text('Join the smart waste management network',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54)),

                  const SizedBox(height: 35),

                  // 🔹 Glassy Signup Card
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
                              color: Colors.white.withOpacity(0.6), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            _buildGlassInput(_companyNameController,
                                'Company Name', Icons.business_rounded),
                            const SizedBox(height: 16),
                            _buildGlassInput(_emailController, 'Official Email',
                                Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildGlassInput(_companyIdController, 'Company ID',
                                Icons.badge_outlined),
                            const SizedBox(height: 16),
                            _buildGlassInput(_phoneController, 'Phone Number',
                                Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildGlassPasswordInput(),
                            const SizedBox(height: 30),

                            // 🔹 Register Button
                            _buildRegisterButton(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  _buildLoginPrompt(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Color(0xFF1565C0)),
        ),
      ),
    );
  }

  Widget _buildGlassInput(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF1565C0), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2972FE), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF2972FE), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGlassPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Set Password',
        labelStyle: const TextStyle(color: Color(0xFF1565C0), fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Color(0xFF2972FE), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.black45,
              size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF2972FE), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _registerCompany,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2972FE),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
          shadowColor: const Color(0xFF2972FE).withOpacity(0.4),
        ),
        child: const Text('Create Company Account',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already registered? ',
            style: TextStyle(color: Colors.black54)),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const CompanyLoginScreen())),
          child: const Text('Sign In',
              style: TextStyle(
                  color: Color(0xFF2972FE), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
