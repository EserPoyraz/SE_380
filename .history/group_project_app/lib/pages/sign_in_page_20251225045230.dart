import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _busy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final signIn = GoogleSignIn.instance;
      await signIn.signOut();

      final GoogleSignInAccount? googleUser =
          await signIn.authenticate();
      if (googleUser == null) {
        _snack('İşlem iptal edildi.');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _snack('Google kimlik doğrulama başarısız.');
        return;
      }

      final credential =
          GoogleAuthProvider.credential(idToken: idToken);

      await FirebaseAuth.instance
          .signInWithCredential(credential);

      final user = FirebaseAuth.instance.currentUser!;
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final doc = await userRef.get();
      if (!doc.exists) {
        await userRef.set({
          'name': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'bmi': null,
          'sets': 0,
          'water': 0,
          'friends': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } on PlatformException catch (e) {
      _snack(e.message ?? e.code);
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0F1A),
              Color(0xFF141A2E),
            ],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Welcome",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Train smart. Stay consistent.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),

                // GOOGLE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _signInWithGoogle,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      _busy
                          ? "Signing in..."
                          : "Continue with Google",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
