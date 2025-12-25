import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:ui'; // Glassmorphism efekti için

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
  // Canlı Renk Paleti
  static const Color darkBg = Color(0xFF0A0E21);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonBlue = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFF8338EC);
  static const Color neonYellow = Color(0xFFFFBE0B);

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
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // Arka plana hafif bir renk sızıntısı (Glow)
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurCircle(neonPurple.withOpacity(0.2)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurCircle(neonBlue.withOpacity(0.2)),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Modern ve Eğlenceli Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SELAM, ${user.displayName?.split(' ')[0] ?? 'ŞAMPİYON'}! 🔥",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.black,
                              ),
                            ),
                            const Text(
                              "Bugün sınırları zorlamaya hazır mısın?",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),

                // Ana Menü Kartları (Grid Görünümü)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildNeonCard(
                        "BMI ÖLÇER", 
                        Icons.monitor_weight_rounded, 
                        [neonBlue, neonPurple],
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BmiPage())),
                      ),
                      _buildNeonCard(
                        "PROGRAMIM", 
                        Icons.bolt_rounded, 
                        [neonPink, neonPurple],
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgramBuilderPage())),
                      ),
                    ]),
                  ),
                ),

                // Takip Araçları (Geniş Kartlar)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionLabel("GÜNLÜK İSTATİSTİKLER"),
                      const SizedBox(height: 16),
                      
                      _buildGlassBox(
                        child: CounterBox(color: neonBlue, userId: user.uid),
                        borderColor: neonBlue,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildGlassBox(
                        child: WaterTrackerBox(color: neonBlue, userId: user.uid),
                        borderColor: neonPink,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Neon Degradeli Kart Tasarımı
  Widget _buildNeonCard(String title, IconData icon, List<Color> colors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Şeffaf Glassmorphism Kutusu
  Widget _buildGlassBox({required Widget child, required Color borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  // Arka Plan Glow Efekti
  Widget _buildBlurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: neonYellow, fontWeight: FontWeight.w900, letterSpacing: 1.2),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.redAccent.withOpacity(0.1),
      ),
      child: IconButton(
        icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
        onPressed: _logout,
      ),
    );
  }
}