import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

const String? kWebClientId = null;

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
    const String kWebClientId =
        "661165033318-vm7m0jr9bmc399lka18226l6vf758mji.apps.googleusercontent.com";

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await GoogleSignIn.instance.initialize(
      //BURAYA BAK GEREKİRSE DOLDUR GEREKİYOR GİBİ
      //HALLETTİK
      //OLMAMIŞ  :')
      serverClientId: kWebClientId,
    );

    await GoogleSignIn.instance.attemptLightweightAuthentication();
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

// ----------------------------
// HOME
// ----------------------------

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

// ----------------------------
// SIGN IN
// ----------------------------

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _busy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    print(msg);
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final signIn = GoogleSignIn.instance;

      if (!signIn.supportsAuthenticate()) {
        _snack(
          'Bu platformda Google Sign-In desteklenmiyor. Android/Web deneyin.',
        );
        return;
      }

      final GoogleSignInAccount? googleUser = await signIn.authenticate();
      if (googleUser == null) {
        _snack('İşlem iptal edildi.');
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // ID TOKEN MUHABBETİ
      if (googleAuth.idToken == null) {
        _snack(
          'idToken null geldi.\n'
          'Çözüm: GoogleSignIn.initialize(serverClientId: WEB_CLIENT_ID) ekle ve\n'
          'Firebase Console’da Google provider + Android SHA-1 ayarlarını kontrol et.',
        );
        return;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _snack('FirebaseAuthException: ${e.code}\n${e.message ?? ''}');
    } on PlatformException catch (e) {
      _snack('PlatformException: ${e.code}\n${e.message ?? ''}');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _busy ? null : _signInWithGoogle,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(
                _busy ? "Signing in..." : "Sign in with Google",
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------
// UI WIDGETS
// ----------------------------

class NavigationBox extends StatelessWidget {
  final String title;
  final Color color;
  final Widget destination;

  const NavigationBox({
    super.key,
    required this.title,
    required this.color,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class CounterBox extends StatefulWidget {
  // SAYAÇ KUTUSU
  final Color color;

  const CounterBox({super.key, required this.color});

  @override
  State<CounterBox> createState() => _CounterBoxState();
}

class _CounterBoxState extends State<CounterBox> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Sets: $counter",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => counter++),
            child: const Text("Set Kaydet 💪"),
          ),
        ],
      ),
    );
  }
}

class WaterTrackerBox extends StatefulWidget {
  // SU TAKİP EDİCİ
  final Color color;

  const WaterTrackerBox({super.key, required this.color});

  @override
  State<WaterTrackerBox> createState() => _WaterTrackerBoxState();
}

class _WaterTrackerBoxState extends State<WaterTrackerBox> {
  int water = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Water : $water ml",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => water += 200),
            child: const Text("Drink 💧 +200 ml"),
          ),
        ],
      ),
    );
  }
}

// ----------------------------
// BMI PAGE
// ----------------------------

class BmiPage extends StatefulWidget {
  // BOY KİLO ORAN SAYFASI
  const BmiPage({super.key});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  String _gender = 'Male';
  double? _bmi;
  String? _category;

  void _calculate() {
    final double? weight = double.tryParse(
      _weightCtrl.text.replaceAll(',', '.'),
    );
    final double? heightCm = double.tryParse(
      _heightCtrl.text.replaceAll(',', '.'),
    );
    if (weight == null || heightCm == null || heightCm <= 0) return;

    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);

    String category;
    if (bmi < 18.5) {
      category = 'Underweight';
    } else if (bmi < 25) {
      category = 'Normal weight';
    } else if (bmi < 30) {
      category = 'Overweight';
    } else {
      category = 'Obesity';
    }

    setState(() {
      _bmi = bmi;
      _category = category;
    });
  }

  String _genderComment() {
    if (_bmi == null) return '';
    if (_gender == 'Male') {
      return 'Not: Erkeklerde kas oranı genelde daha yüksek olabilir — bel çevresi ve kas kütlesine bakmak faydalıdır.';
    } else {
      return 'Not: Kadınlarda yağ oranı farklı olabilir — bel/kalça oranı ve %vücut yağını ölçmek daha açıklayıcı olur.';
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BMI Hesaplayıcı')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilo (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Boy (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Cinsiyet:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Erkek')),
                    DropdownMenuItem(value: 'Female', child: Text('Kadın')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Hesapla'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_bmi != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'BMI: ${_bmi!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kategori: $_category',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _genderComment(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Uyarı: BMI tek başına vücut kompozisyonunu göstermez. Ölçümler ve doktor değerlendirmesi önemlidir.',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------
// PROGRAM BUILDER
// ----------------------------

class ProgramBuilderPage extends StatefulWidget {
  const ProgramBuilderPage({super.key});

  @override
  State<ProgramBuilderPage> createState() => _ProgramBuilderPageState();
}

class _ProgramBuilderPageState extends State<ProgramBuilderPage> {
  //PROGRAM YAPMA SAYFASI
  String _location = 'Home';
  String _split = 'Push/Pull/Legs';
  String _goal = 'Strength';

  Map<String, List<Exercise>> program = {};

  void _generateProgram() {
    final generator = ProgramGenerator(
      location: _location,
      split: _split,
      goal: _goal,
    );
    setState(() => program = generator.generate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Program Oluşturucu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lokasyon:'),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Ev'),
                  selected: _location == 'Home',
                  onSelected: (_) => setState(() => _location = 'Home'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Gym'),
                  selected: _location == 'Gym',
                  onSelected: (_) => setState(() => _location = 'Gym'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Split / Bölünme:'),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Push/Pull/Legs'),
                  selected: _split == 'Push/Pull/Legs',
                  onSelected: (_) => setState(() => _split = 'Push/Pull/Legs'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Upper/Lower'),
                  selected: _split == 'Upper/Lower',
                  onSelected: (_) => setState(() => _split = 'Upper/Lower'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Hedef:'),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Strength'),
                  selected: _goal == 'Strength',
                  onSelected: (_) => setState(() => _goal = 'Strength'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Fat Loss'),
                  selected: _goal == 'Fat Loss',
                  onSelected: (_) => setState(() => _goal = 'Fat Loss'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Conditioning'),
                  selected: _goal == 'Conditioning',
                  onSelected: (_) => setState(() => _goal = 'Conditioning'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _generateProgram,
                child: const Text('Program Oluştur'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: program.isEmpty
                  ? const Center(child: Text('Henüz program oluşturulmadı'))
                  : ListView(
                      children: program.entries.map((e) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...e.value.map(
                                  (ex) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Text(
                                      '${ex.name} — ${ex.sets} x ${ex.reps} ${ex.note != null ? '(${ex.note})' : ''}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class Exercise {
  final String name;
  final int sets;
  final String reps;
  final String? note;

  Exercise(this.name, this.sets, this.reps, {this.note});
}

class ProgramGenerator {
  final String location;
  final String split;
  final String goal;
  final Random _rnd = Random();

  ProgramGenerator({
    required this.location,
    required this.split,
    required this.goal,
  });

  Map<String, List<Exercise>> generate() {
    //AŞAĞIDAKİ HERŞEY SİLİNİP Aİ İMPLEMENTE EDİLECEK
    if (split == 'Push/Pull/Legs') {
      return {'Push': _buildPush(), 'Pull': _buildPull(), 'Legs': _buildLegs()};
    } else {
      return {'Upper': _buildUpper(), 'Lower': _buildLower()};
    }
  }

  int _setsForGoal() {
    switch (goal) {
      case 'Strength':
        return 4;
      default:
        return 3;
    }
  }

  String _repsForGoal(String exerciseType) {
    if (goal == 'Strength') return '4-6';
    if (goal == 'Fat Loss') return '10-15';
    if (goal == 'Conditioning') {
      if (exerciseType == 'cardio') return '30-60s';
      return '12-15';
    }
    return '8-12';
  }

  List<String> _pool(String kind) {
    final home = {
      'pushCompound': [
        'Push-ups',
        'Incline Push-ups',
        'Dumbbell Shoulder Press',
      ],
      'pushAccessory': ['Dips (Bench)', 'Triceps Kickback', 'Pike Push-up'],
      'pullCompound': ['Inverted Row', 'One-arm Dumbbell Row', 'Doorway Row'],
      'pullAccessory': ['Biceps Curl (DB)', 'Hammer Curl', 'Reverse Fly'],
      'legCompound': ['Squats', 'Bulgarian Split Squat', 'Reverse Lunge'],
      'legAccessory': [
        'Hamstring Curl (Swiss Ball)',
        'Calf Raise',
        'Glute Bridge',
      ],
      'conditioning': ['Jumping Jacks', 'Burpees', 'Mountain Climbers'],
    };

    final gym = {
      'pushCompound': [
        'Barbell Bench Press',
        'Seated Dumbbell Press',
        'Incline Bench Press',
      ],
      'pushAccessory': ['Cable Fly', 'Triceps Pushdown', 'Chest Dips'],
      'pullCompound': [
        'Barbell Row',
        'Pull-up/Lat Pulldown',
        'Chest Supported Row',
      ],
      'pullAccessory': ['EZ Bar Curl', 'Face Pull', 'Seated Cable Row (light)'],
      'legCompound': ['Back Squat', 'Deadlift', 'Leg Press'],
      'legAccessory': ['Leg Curl', 'Leg Extension', 'Seated Calf Raise'],
      'conditioning': ['Bike', 'Rowing Machine', 'Treadmill Sprints'],
    };

    final map = location == 'Home' ? home : gym;
    return List<String>.from(map[kind] ?? []);
  }

  List<Exercise> _pick(
    String poolKind,
    int count,
    String type, {
    String? note,
  }) {
    final pool = _pool(poolKind);
    final picked = <Exercise>[];
    final used = <int>{};

    for (var i = 0; i < count && i < pool.length; i++) {
      int idx;
      do {
        idx = _rnd.nextInt(pool.length);
      } while (used.contains(idx) && used.length < pool.length);

      used.add(idx);
      picked.add(
        Exercise(pool[idx], _setsForGoal(), _repsForGoal(type), note: note),
      );
    }
    return picked;
  }

  List<Exercise> _buildPush() {
    final out = <Exercise>[];
    out.addAll(_pick('pushCompound', 2, 'compound'));
    out.addAll(_pick('pushAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Circuit-style'));
    }
    return out;
  }

  List<Exercise> _buildPull() {
    final out = <Exercise>[];
    out.addAll(_pick('pullCompound', 2, 'compound'));
    out.addAll(_pick('pullAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Circuit-style'));
    }
    return out;
  }

  List<Exercise> _buildLegs() {
    final out = <Exercise>[];
    out.addAll(_pick('legCompound', 2, 'compound'));
    out.addAll(_pick('legAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Interval'));
    }
    return out;
  }

  List<Exercise> _buildUpper() {
    final out = <Exercise>[];
    out.addAll(_pick('pushCompound', 1, 'compound'));
    out.addAll(_pick('pullCompound', 1, 'compound'));
    out.addAll(_pick('pushAccessory', 1, 'accessory'));
    out.addAll(_pick('pullAccessory', 1, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Short Circuit'));
    }
    return out;
  }

  List<Exercise> _buildLower() {
    final out = <Exercise>[];
    out.addAll(_pick('legCompound', 2, 'compound'));
    out.addAll(_pick('legAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Sled/Intervals'));
    }
    return out;
  }
}
