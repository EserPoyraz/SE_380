import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../widgets/custom_widgets.dart'; // Box'lar burada
import 'bmi_page.dart';
import 'program_builder_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FitnessApp"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          NavigationBox(
            title: "BMI Calculator",
            color: Colors.tealAccent,
            destination: const BmiPage(),
          ),
          const SizedBox(height: 24),
          NavigationBox(
            title: "Program Oluştur",
            color: Colors.deepPurpleAccent,
            destination: const ProgramBuilderPage(),
          ),
          const SizedBox(height: 24),
          const CounterBox(color: Colors.purpleAccent),
          const SizedBox(height: 24),
          const WaterTrackerBox(color: Colors.cyanAccent),
        ],
      ),
    );
  }
}