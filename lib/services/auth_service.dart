import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance GoogleSignIn didefinisikan di sini agar konsisten
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  String _generateGravatarUrl(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    final bytes = utf8.encode(trimmedEmail);
    final hash = md5.convert(bytes).toString();
    return 'https://www.gravatar.com/avatar/$hash?s=200&d=identicon';
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      final gravatarUrl = _generateGravatarUrl(email);

      if (user != null) {
        await user.updatePhotoURL(gravatarUrl);
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': 'user',
          'photoUrl': gravatarUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak terduga');
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint("Reset Password Error: ${e.code}");
      throw e;
    } catch (e) {
      throw Exception("Terjadi kesalahan saat mengirim email reset.");
    }
  }

  // --- GOOGLE SIGN IN DENGAN FIX PIGEON ERROR ---
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Membersihkan sesi lama sebelum memulai login baru
      // Ini kunci untuk menghindari error 'PigeonUserDetails'
      await _googleSignIn.signOut();

      // 2. Memulai proses login Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Jika user membatalkan pilihan akun
      if (googleUser == null) return null;

      // 3. Mendapatkan detail otentikasi
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Membuat kredensial baru untuk Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Masuk ke Firebase menggunakan kredensial Google
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      // 6. Simpan data ke Firestore jika ini pengguna baru
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email ?? '',
            'role': 'user',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error: ${e.code}");
      throw e;
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      // Melempar error agar ditangkap oleh SnackBar di UI
      throw Exception(e.toString());
    }
  }

  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? (doc.data()?['role'] ?? 'user') : 'user';
    } catch (e) {
      return 'user';
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out dari Google dan Firebase
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }
}
