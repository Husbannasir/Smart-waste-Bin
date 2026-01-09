import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Sweeper_login.dart';

class SweeperSignUpScreen extends StatefulWidget {
  const SweeperSignUpScreen({super.key});

  @override
  State<SweeperSignUpScreen> createState() => _SweeperSignUpScreenState();
}

class _SweeperSignUpScreenState extends State<SweeperSignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _sweeperIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  Future<void> _registerSweeper() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final sweeperId = _sweeperIdController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        sweeperId.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ Please fill all fields"),
            backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection("sweepers").doc(user.uid).set({
          "uid": user.uid,
          "name": name,
          "email": email,
          "sweeperId": sweeperId,
          "phone": phone,
          "createdAt": FieldValue.serverTimestamp(),
          "role": "sweeper", // Added for role-based access
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("✅ Registration Successful!"),
                backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const SweeperLoginScreen()));
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("❌ ${e.message}"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative shapes
            Positioned(
                top: -50,
                left: -50,
                child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white.withOpacity(0.2))),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Icon(Icons.person_add_rounded,
                          size: 70, color: Color(0xFF2D3142)),
                      const SizedBox(height: 10),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D3142),
                            letterSpacing: 1.1),
                      ),
                      const Text('Join the clean city mission!',
                          style:
                              TextStyle(fontSize: 16, color: Colors.black54)),

                      const SizedBox(height: 30),

                      // Glassmorphic Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2),
                            ),
                            child: Column(
                              children: [
                                _buildInputField(_nameController, 'Full Name',
                                    Icons.person_outline),
                                const SizedBox(height: 15),
                                _buildInputField(_emailController, 'Email',
                                    Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 15),
                                _buildInputField(_sweeperIdController,
                                    'Sweeper ID', Icons.badge_outlined),
                                const SizedBox(height: 15),
                                _buildInputField(
                                    _phoneController,
                                    'Phone Number',
                                    Icons.phone_android_outlined,
                                    keyboardType: TextInputType.phone),
                                const SizedBox(height: 15),
                                _buildInputField(
                                  _passwordController,
                                  'Set Password',
                                  Icons.lock_outline_rounded,
                                  isPassword: true,
                                  suffix: IconButton(
                                    icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed:
                                        _loading ? null : _registerSweeper,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF22B5FE),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      elevation: 8,
                                      shadowColor: const Color(0xFF22B5FE)
                                          .withOpacity(0.4),
                                    ),
                                    child: _loading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : const Text('REGISTER',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Login Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? ",
                              style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Login',
                                style: TextStyle(
                                    color: Color(0xFF22B5FE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false,
      TextInputType keyboardType = TextInputType.text,
      Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: Color(0xFF2D3142), fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: const Color(0xFF2D3142), size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
