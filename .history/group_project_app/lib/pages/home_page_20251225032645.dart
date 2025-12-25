import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/custom_widgets.dart';
import 'bmi_page.dart';
import 'program_builder_page.dart';
import '../services/user_initializer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    UserInitializer.ensureUserExists();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("FitnessApp"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          NavigationBox(
            title: "BMI Calculator",
            color: const Color.fromARGB(255, 0, 44, 133),
            destination: const BmiPage(),
          ),
          const SizedBox(height: 24),

          NavigationBox(
            title: "Program Oluştur",
            color: const Color.fromARGB(255, 0, 44, 133),
            destination: const ProgramBuilderPage(),
          ),
          const SizedBox(height: 24),

          CounterBox(
            color: const Color.fromARGB(255, 0, 44, 133),
            userId: user.uid,
          ),
          const SizedBox(height: 24),

          WaterTrackerBox(
            color: const Color.fromARGB(255, 0, 44, 133),
            userId: user.uid,
          ),
        ],
      ),
    );
  }
}


