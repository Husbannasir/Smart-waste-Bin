import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSweepersScreen extends StatefulWidget {
  const AdminSweepersScreen({super.key});

  @override
  State<AdminSweepersScreen> createState() => _AdminSweepersScreenState();
}

class _AdminSweepersScreenState extends State<AdminSweepersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // 🔹 Add Sweeper
  Future<void> _addSweeper(String name, String email, String password) async {
    try {
      // Validation
      if (RegExp(r'[0-9]').hasMatch(name)) {
        throw Exception("Name cannot contain numbers");
      }
      if (!email.contains("@") || !email.contains(".")) {
        throw Exception("Invalid email format");
      }
      if (password.length < 6) {
        throw Exception("Password must be at least 6 characters");
      }

      // Create Sweeper user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store sweeper details in Firestore
      await _firestore
          .collection("sweepers")
          .doc(userCredential.user!.uid)
          .set({
        "uid": userCredential.user!.uid,
        "name": name,
        "email": email,
        "role": "sweeper",
        "companyId": null,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sweeper added successfully")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Auth Error: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  void _showAddSweeperDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Add Sweeper"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  _addSweeper(
                      nameController.text.trim(),
                      emailController.text.trim(),
                      passwordController.text.trim());
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠ All fields are required")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Delete Sweeper
  Future<void> _deleteSweeper(String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete sweeper $email?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(c, false),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection("sweepers").doc(uid).delete();
      // NOTE: Direct FirebaseAuth user delete is not possible from client.
      // For full delete, you need Firebase Admin SDK on backend.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sweeper deleted from Firestore")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Delete failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Sweepers"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSweeperDialog,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by sweeper name...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("sweepers")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("❌ Error loading sweepers"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sweepers = snapshot.data!.docs.where((doc) {
                  final name = (doc["name"] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (sweepers.isEmpty) {
                  return const Center(child: Text("No sweepers found"));
                }

                return ListView.builder(
                  itemCount: sweepers.length,
                  itemBuilder: (context, index) {
                    final sweeper = sweepers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.green),
                        title: Text("${sweeper["name"]} (ID: ${sweeper.id})"),
                        subtitle: Text(sweeper["email"]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteSweeper(sweeper.id, sweeper["email"]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
