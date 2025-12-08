import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FitnessApp")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          NavigationBox(
            title: "BMI Calculator",
            color: Colors.tealAccent.shade700,
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

          // Keep Water Tracker
          WaterTrackerBox(color: Colors.cyanAccent),
        ],
      ),
    );
  }
}

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
// BMI Page
// ----------------------------

class BmiPage extends StatefulWidget {
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
    // Use standard WHO BMI categories but add a small gender-aware note.
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
    // Provide a short note that body composition varies and how to interpret.
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
// Program Builder
// ----------------------------

class ProgramBuilderPage extends StatefulWidget {
  const ProgramBuilderPage({super.key});

  @override
  State<ProgramBuilderPage> createState() => _ProgramBuilderPageState();
}

class _ProgramBuilderPageState extends State<ProgramBuilderPage> {
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
    final generated = generator.generate();
    setState(() => program = generated);
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
  final String location; // Home or Gym
  final String split; // Push/Pull/Legs or Upper/Lower
  final String goal; // Strength, Fat Loss, Conditioning
  final Random _rnd = Random();

  ProgramGenerator({
    required this.location,
    required this.split,
    required this.goal,
  });

  Map<String, List<Exercise>> generate() {
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
      case 'Fat Loss':
        return 3;
      case 'Conditioning':
        return 3;
      default:
        return 3;
    }
  }

  String _repsForGoal(String exerciseType) {
    // exerciseType can be 'compound' or 'accessory' or 'cardio'
    if (goal == 'Strength') return '4-6';
    if (goal == 'Fat Loss') return '10-15';
    if (goal == 'Conditioning') {
      if (exerciseType == 'cardio') return '30-60s';
      return '12-15';
    }
    return '8-12';
  }

  List<String> _pool(String kind) {
    // kind: pushCompound, pushAccessory, pullCompound, pullAccessory, legCompound, legAccessory, conditioning
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
      final name = pool[idx];
      picked.add(
        Exercise(name, _setsForGoal(), _repsForGoal(type), note: note),
      );
    }
    return picked;
  }

  List<Exercise> _buildPush() {
    final List<Exercise> out = [];
    out.addAll(_pick('pushCompound', 2, 'compound'));
    out.addAll(_pick('pushAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Circuit-style'));
    }
    return out;
  }

  List<Exercise> _buildPull() {
    final List<Exercise> out = [];
    out.addAll(_pick('pullCompound', 2, 'compound'));
    out.addAll(_pick('pullAccessory', 2, 'accessory'));
    if (goal == 'Conditioning')
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Circuit-style'));
    return out;
  }

  List<Exercise> _buildLegs() {
    final List<Exercise> out = [];
    out.addAll(_pick('legCompound', 2, 'compound'));
    out.addAll(_pick('legAccessory', 2, 'accessory'));
    if (goal == 'Conditioning')
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Interval'));
    return out;
  }

  List<Exercise> _buildUpper() {
    final List<Exercise> out = [];
    out.addAll(_pick('pushCompound', 1, 'compound'));
    out.addAll(_pick('pullCompound', 1, 'compound'));
    out.addAll(_pick('pushAccessory', 1, 'accessory'));
    out.addAll(_pick('pullAccessory', 1, 'accessory'));
    if (goal == 'Conditioning')
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Short Circuit'));
    return out;
  }

  List<Exercise> _buildLower() {
    final List<Exercise> out = [];
    out.addAll(_pick('legCompound', 2, 'compound'));
    out.addAll(_pick('legAccessory', 2, 'accessory'));
    if (goal == 'Conditioning')
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Sled/Intervals'));
    return out;
  }
}
