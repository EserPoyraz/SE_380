import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'pages/main_scaffold.dart';

import 'pages/sign_in_page.dart';
import 'pages/bmi_page.dart';

// CLIENT TYPE 3 WEB CLIENT ID ::::::
const String kServerClientId =
    "661165033318-vm7m0jr9bmc399lka18226l6vf758mji.apps.googleusercontent.com";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _Bootstrapper(),
        routes: {
        '/bmi': (_) => const BmiPage(),
        },
      
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
    // INITIALIZE AT EVERY PLATFORM
    await GoogleSignIn.instance.initialize(serverClientId: kServerClientId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _SplashLoading();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnap) {
            if (authSnap.connectionState == ConnectionState.waiting) {
              return const _SplashLoading();
            }
            if (authSnap.hasData) return const MainScaffold();
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
