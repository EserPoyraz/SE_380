import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/user_initializer.dart';
import '../widgets/custom_widgets.dart';
import 'bmi_page.dart';
import 'program_builder_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = const Color.fromARGB(255, 0, 44, 133);

  @override
  void initState() {
    super.initState();
    UserInitializer.ensureUserExists();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text("FitnessApp"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          /// 🔹 USER HEADER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    user.photoURL ?? 'https://i.pravatar.cc/150',
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Let’s improve today 💪",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 32),

          /// 🔹 MAIN ACTIONS
          Row(
            children: [
              Expanded(
                child: NavigationBox(
                  title: "BMI",
                  color: primaryColor,
                  destination: const BmiPage(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NavigationBox(
                  title: "Program",
                  color: primaryColor,
                  destination: const ProgramBuilderPage(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          /// 🔹 STATS
          Row(
            children: [
              Expanded(
                child: CounterBox(
                  color: primaryColor,
                  userId: user.uid,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WaterTrackerBox(
                  color: primaryColor,
                  userId: user.uid,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
