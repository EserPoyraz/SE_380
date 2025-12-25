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
    // Ana tema rengimiz (Koyu Lacivert/Modern Mavi)
    const primaryColor = Color(0xFF002C85);
    const accentColor = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Hafif gri arka plan profesyonel gösterir
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text("FitnessApp", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // Kullanıcı Karşılama Bölümü
          _buildHeader(user.displayName ?? "Kullanıcı"),
          const SizedBox(height: 30),

          // Grid veya Liste Yapısında Kartlar
          _buildActionCard(
            context,
            title: "BMI Hesaplayıcı",
            subtitle: "Vücut kitle indeksini takip et",
            icon: Icons.monitor_weight_outlined,
            gradient: [primaryColor, accentColor],
            destination: const BmiPage(),
          ),
          const SizedBox(height: 16),

          _buildActionCard(
            context,
            title: "Program Oluştur",
            subtitle: "Sana özel antrenman planı",
            icon: Icons.fitness_center_rounded,
            gradient: [const Color(0xFF1A237E), primaryColor],
            destination: const ProgramBuilderPage(),
          ),
          
          const SizedBox(height: 30),
          const Text("Günlük Takip", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // İstatistik Kutuları
          CounterBox(color: primaryColor, userId: user.uid),
          const SizedBox(height: 16),
          WaterTrackerBox(color: Colors.blueAccent, userId: user.uid),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Merhaba,", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Widget destination,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}