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
  // Renk Paleti - Deep Midnight & Electric Neon
  static const Color bgColor = Color(0xFF0F172A); // Koyu Lacivert/Siyah
  static const Color cardColor = Color(0xFF1E293B); // Kart Arka Planı
  static const Color accentColor = Color(0xFF38BDF8); // Electric Blue
  static const Color secondaryAccent = Color(0xFF818CF8); // Soft Purple

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
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar (Sliver)
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                "HOŞ GELDİN, ${user.displayName?.split(' ')[0].toUpperCase() ?? 'ATHLETE'}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(Icons.logout_rounded, color: accentColor),
                  onPressed: _logout,
                ),
              ),
            ],
          ),

          // İçerik Listesi
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle("AKTİVİTE MERKEZİ"),
                const SizedBox(height: 16),
                
                // Grid yapısı veya yan yana duran aksiyon kartları
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        "BMI",
                        Icons.speed_rounded,
                        accentColor,
                        const BmiPage(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        "PROGRAM",
                        Icons.fitness_center_rounded,
                        secondaryAccent,
                        const ProgramBuilderPage(),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                _buildSectionTitle("GÜNLÜK TAKİP"),
                const SizedBox(height: 16),

                // Özel Widget'larınıza Pro Dokunuş (Sarmalayıcı içine alınmıştır)
                _buildProContainer(
                  child: CounterBox(color: accentColor, userId: user.uid),
                ),
                const SizedBox(height: 16),
                _buildProContainer(
                  child: WaterTrackerBox(color: secondaryAccent, userId: user.uid),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Bölüm Başlıkları
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  // Aksiyon Kartları (BMI & Program)
  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Widget Sarmalayıcı (Counter ve Water Box için)
  Widget _buildProContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(4), // İç widget padding'i
      child: child,
    );
  }
}