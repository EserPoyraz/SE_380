import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Eğer main'de özel bir system işlemi yapmıyorsan buna gerek kalmadı.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

// YENİ EKLENEN IMPORTLAR (Sayfaları tanıması için şart)
import 'pages/home_page.dart';
import 'pages/sign_in_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _Bootstrapper(),
    );
  }
}

class _Bootstrapper extends StatefulWidget {
  const _Bootstrapper({super.key});

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  late final Future<void> _initFuture = _init();

  Future<void> _init() async {
    // Web Client ID'yi buraya sabitliyoruz
    const String kWebClientId =
        "661165033318-vm7m0jr9bmc399lka18226l6vf758mji.apps.googleusercontent.com";

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await GoogleSignIn.instance.initialize(serverClientId: kWebClientId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        // Firebase yüklenirken bekleme ekranı
        if (snap.connectionState != ConnectionState.done) {
          return const _SplashLoading();
        }

        // Auth durumunu dinle
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnap) {
            if (authSnap.connectionState == ConnectionState.waiting) {
              return const _SplashLoading();
            }
            // Kullanıcı varsa Home, yoksa SignIn sayfasına git
            if (authSnap.hasData) return const HomePage();
            return const SignInPage();
          },
        );
      },
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}