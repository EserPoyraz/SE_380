import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDocStream =
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snap.data!.data() ?? {};
            final name = (data['name'] as String?) ?? "User";
            final email = (data['email'] as String?) ??
                (FirebaseAuth.instance.currentUser?.email ?? "");
            final photoUrl = (data['photoUrl'] as String?) ?? "";

            final friends = (data['friends'] as List?)?.cast<String>() ?? [];
            final sets = (data['sets'] as int?) ?? 0;
            final water = (data['water'] as int?) ?? 0;

            final heightCm = (data['height'] as num?)?.toDouble();
            final weightKg = (data['weight'] as num?)?.toDouble();

            // BMI hesap (eğer height/weight varsa)
            double? bmi;
            if (heightCm != null &&
                heightCm > 0 &&
                weightKg != null &&
                weightKg > 0) {
              final m = heightCm / 100.0;
              bmi = weightKg / (m * m);
            }

            final currentProgram =
                (data['currentProgram'] as Map?)?.cast<String, dynamic>();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  name: name,
                  email: email,
                  friendsCount: friends.length,
                  photoUrl: photoUrl,
                ),
                const SizedBox(height: 14),

                // TODAY
                Text(
                  "Today",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        title: "Sets",
                        value: "$sets",
                        subtitle: "Completed",
                        icon: Icons.fitness_center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        title: "Water",
                        value: "${water}ml",
                        subtitle: "Intake",
                        icon: Icons.water_drop,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // HEALTH
                Text(
                  "Health",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Body Metrics",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                (bmi == null) ? "Unknown" : _bmiLabel(bmi),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _metricRow("BMI",
                            bmi == null ? "-" : bmi.toStringAsFixed(1)),
                        _metricRow("Height",
                            heightCm == null ? "-" : "${heightCm.toInt()} cm"),
                        _metricRow("Weight",
                            weightKg == null ? "-" : "${weightKg.toInt()} kg"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // PROGRAM
                Text(
                  "Program",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                _ProgramCard(
                  uid: uid,
                  currentProgram: currentProgram,
                ),

                const SizedBox(height: 14),

                // ACTIONS
                Text(
                  "Actions",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: "Edit Profile",
                        style: AppButtonStyle.glass,
                        icon: Icons.edit,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _EditProfileSheet(
                              uid: uid,
                              initialName: name,
                              initialHeight: heightCm,
                              initialWeight: weightKg,
                              initialSets: sets,
                              initialWater: water,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: "Sign out",
                        style: AppButtonStyle.glass,
                        icon: Icons.logout,
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _metricRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          Text(
            v,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _bmiLabel(double bmi) {
    if (bmi < 18.5) return "Low";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "High";
    return "Very High";
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.email,
    required this.friendsCount,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final int friendsCount;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white24,
              backgroundImage:
                  photoUrl.trim().isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.trim().isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0] : "U",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(text: "$friendsCount friends"),
                      const _Chip(text: "Online"),
                    ],
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

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(icon, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
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

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.uid,
    required this.currentProgram,
  });

  final String uid;
  final Map<String, dynamic>? currentProgram;

  @override
  Widget build(BuildContext context) {
    if (currentProgram == null) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _progIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "No active program.\nGenerate one from Program Builder.",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final title = (currentProgram?['title'] as String?) ?? "Program";
    final goal = (currentProgram?['goal'] as String?) ?? "";
    final split = (currentProgram?['split'] as String?) ?? "";
    final location = (currentProgram?['location'] as String?) ?? "";

    // 🔥 ÖNEMLİ: currentProgram var ama user/programs içinde yoksa stale demektir.
    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('programs')
        .where('title', isEqualTo: title)
        .limit(1);

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: q.get(),
      builder: (context, snap) {
        final exists = snap.hasData && snap.data!.docs.isNotEmpty;

        if (!exists) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _progIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Saved programs deleted.\nThis active program is outdated.",
                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({'currentProgram': FieldValue.delete()});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Active program cleared")),
                      );
                    },
                    child: const Text(
                      "Clear",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _progIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [goal, split, location].where((e) => e.isNotEmpty).join(" • "),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    "Active",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _progIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white70),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.uid,
    required this.initialName,
    required this.initialHeight,
    required this.initialWeight,
    required this.initialSets,
    required this.initialWater,
  });

  final String uid;
  final String initialName;
  final double? initialHeight;
  final double? initialWeight;
  final int initialSets;
  final int initialWater;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _sets;
  late final TextEditingController _water;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _height = TextEditingController(
        text: widget.initialHeight == null ? "" : widget.initialHeight!.toStringAsFixed(0));
    _weight = TextEditingController(
        text: widget.initialWeight == null ? "" : widget.initialWeight!.toStringAsFixed(0));
    _sets = TextEditingController(text: widget.initialSets.toString());
    _water = TextEditingController(text: widget.initialWater.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    _sets.dispose();
    _water.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));
  int? _parseInt(String s) => int.tryParse(s.trim());

  Future<void> _save() async {
    final name = _name.text.trim();
    final h = _parseDouble(_height.text);
    final w = _parseDouble(_weight.text);
    final sets = _parseInt(_sets.text);
    final water = _parseInt(_water.text);

    // basit validasyon
    if (name.isEmpty) {
      _snack("Name cannot be empty");
      return;
    }

    double? bmi;
    if (h != null && h > 0 && w != null && w > 0) {
      final m = h / 100.0;
      bmi = w / (m * m);
    }

    final update = <String, dynamic>{
      'name': name,
    };

    if (h != null && h > 0) update['height'] = h;
    if (w != null && w > 0) update['weight'] = w;
    if (bmi != null) update['bmi'] = bmi;

    if (sets != null && sets >= 0) update['sets'] = sets;
    if (water != null && water >= 0) update['water'] = water;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .set(update, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.pop(context);
    _snack("Profile updated ✅");
  }

  Future<void> _resetSetsWater() async {
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'sets': 0,
      'water': 0,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _sets.text = "0";
      _water.text = "0";
    });
    _snack("Sets & water reset");
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white12),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _field("Name Surname", _name, TextInputType.text),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field("Height (cm)", _height, TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field("Weight (kg)", _weight, TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field("Daily Sets", _sets, TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field("Water (ml)", _water, TextInputType.number),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: "Reset sets & water",
                        style: AppButtonStyle.glass,
                        icon: Icons.restart_alt,
                        onPressed: _resetSetsWater,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        text: "Save",
                        icon: Icons.check,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
      String label, TextEditingController c, TextInputType keyboardType) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
