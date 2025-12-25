import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    final name = user.displayName?.split(" ").first ?? "Athlete";

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      body: Stack(
        children: [
          // BACKGROUND GLOW
          Positioned(
            top: -120,
            left: -80,
            child: _GlowCircle(color: Colors.purpleAccent),
          ),
          Positioned(
            bottom: -140,
            right: -100,
            child: _GlowCircle(color: Colors.cyanAccent),
          ),

          ListView(
            padding: EdgeInsets.zero,
            children: [
              // ================= HEADER =================
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  name[0],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.power_settings_new,
                                  color: Colors.redAccent,
                                ),
                                onPressed: _logout,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "Welcome back,",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8E2DE2),
                                  Color(0xFF4A00E0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "🔥 Consistency is power",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ================= ACTIONS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        title: "Body Analysis",
                        subtitle: "BMI & metrics",
                        icon: Icons.monitor_weight_outlined,
                        gradient: const [
                          Color(0xFF00C6FF),
                          Color(0xFF0072FF),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BmiPage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionTile(
                        title: "Training",
                        subtitle: "AI workout",
                        icon: Icons.fitness_center,
                        gradient: const [
                          Color(0xFFFF512F),
                          Color(0xFFF09819),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProgramBuilderPage(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ================= DAILY PERFORMANCE =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text(
                  "Daily Performance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatWrapper(
                        height: 190,
                        child: CounterBox(
                          color: Colors.deepPurpleAccent,
                          userId: user.uid,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatWrapper(
                        height: 190,
                        child: WaterTrackerBox(
                          color: Colors.cyanAccent,
                          userId: user.uid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),
              const Center(
                child: Text(
                  "Built for consistency. Designed for winners.",
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= UI HELPERS =================

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34, color: Colors.white),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatWrapper extends StatelessWidget {
  final Widget child;
  final double height;

  const _StatWrapper({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(child: child),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  const _GlowCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.45), Colors.transparent],
        ),
      ),
    );
  }
}
