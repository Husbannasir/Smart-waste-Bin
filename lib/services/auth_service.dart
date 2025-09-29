import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register admin
  Future<String?> registerAdmin({
    required String fullName,
    required String email,
    required String password,
    required String zoneId,
    required String phoneNumber,
  }) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('admins').doc(userCred.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'zoneId': zoneId,
        'phone': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCred.user!.uid;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Login admin using Zone ID
  Future<String?> loginAdminWithZoneId({
    required String zoneId,
    required String password,
  }) async {
    try {
      // 🔎 Lookup email from Firestore
      QuerySnapshot snapshot = await _firestore
          .collection('admins')
          .where('zoneId', isEqualTo: zoneId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 'Zone ID not found';

      String email = snapshot.docs.first['email'];

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return _auth.currentUser?.uid;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Send OTP
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP
  Future<String?> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      await _auth.signInWithCredential(credential);
      return _auth.currentUser?.uid;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}