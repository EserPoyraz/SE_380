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
    // Kullanıcının ismini alalım (Google ile giriş yapıldıysa)
    final String displayName = user.displayName?.split(' ')[0] ?? "Şampiyon";

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu arka plan
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "MERHABA, $displayName! 🔥",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E2E)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            const Text(
              "Bugün sınırlarını zorlamaya hazır mısın?",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 25),

            // BMI Kartı - Neon Mavi Görüntü
            _buildActionCard(
              context,
              title: "Vücut Analizi 🧬",
              subtitle: "İdeal formuna ne kadar yakınsın?",
              color: const Color(0xFF00D2FF),
              destination: const BmiPage(),
              icon: Icons.monitor_weight_outlined,
            ),
            const SizedBox(height: 20),

            // Program Kartı - Neon Mor Görüntü
            _buildActionCard(
              context,
              title: "Antrenman Planla ⚡",
              subtitle: "Kendi efsaneni yazmaya başla!",
              color: const Color(0xFF9D50BB),
              destination: const ProgramBuilderPage(),
              icon: Icons.fitness_center_rounded,
            ),
            const SizedBox(height: 30),

            // İstatistik Başlığı
            const Row(
              children: [
                Icon(Icons.auto_graph, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Text(
                  "GÜNLÜK TAKİP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Sayaç Kutusu (Özelleştirilmiş Widget'larınızı sarar)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: CounterBox(
                color: Colors.orangeAccent,
                userId: user.uid,
              ),
            ),
            const SizedBox(height: 20),

            // Su Takip Kutusu
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: WaterTrackerBox(
                color: Colors.blueAccent,
                userId: user.uid,
              ),
            ),
            
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "Pes etmek yok, devam et! 💪",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Özel Kart Tasarımı Metodu
  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required Color color,
      required Widget destination,
      required IconData icon}) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => destination)),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}