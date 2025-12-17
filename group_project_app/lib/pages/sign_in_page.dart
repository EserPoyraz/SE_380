import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _busy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    print(msg);
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final signIn = GoogleSignIn.instance;

      if (!signIn.supportsAuthenticate()) {
        _snack(
          'Bu platformda Google Sign-In desteklenmiyor. Android/Web deneyin.',
        );
        return;
      }

      final GoogleSignInAccount? googleUser = await signIn.authenticate();
      if (googleUser == null) {
        _snack('İşlem iptal edildi.');
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // ID TOKEN MUHABBETİ
      if (googleAuth.idToken == null) {
        _snack(
          'idToken null geldi.\n'
          'Çözüm: GoogleSignIn.initialize(serverClientId: WEB_CLIENT_ID) ekle ve\n'
          'Firebase Console’da Google provider + Android SHA-1 ayarlarını kontrol et.',
        );
        return;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _snack('FirebaseAuthException: ${e.code}\n${e.message ?? ''}');
    } on PlatformException catch (e) {
      _snack('PlatformException: ${e.code}\n${e.message ?? ''}');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _busy ? null : _signInWithGoogle,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(
                _busy ? "Signing in..." : "Sign in with Google",
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}