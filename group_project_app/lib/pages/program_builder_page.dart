import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/ai_workout_generator.dart';
import '../services/program_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../theme/app_theme.dart';
import 'program_detail_page.dart';

class ProgramBuilderPage extends StatefulWidget {
  const ProgramBuilderPage({super.key});

  @override
  State<ProgramBuilderPage> createState() => _ProgramBuilderPageState();
}

class _ProgramBuilderPageState extends State<ProgramBuilderPage>
    with SingleTickerProviderStateMixin {
  // tabs and controllers
  late final TabController _tab;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // user selections state
  String _location = 'Home';
  String _split = 'Push/Pull/Legs';
  String _goal = 'Strength';

  // loading and services
  bool _busy = false;

  final ProgramRepository _repo = ProgramRepository();
  final AiWorkoutGenerator _generator = const AiWorkoutGenerator();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // snack message helper
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surface.withOpacity(0.95),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // delete confirmation dialog
  Future<bool> _confirmDelete(String title) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Delete program?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '"$title" will be permanently deleted.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonOrange.withOpacity(0.9),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  double? _parseNum(TextEditingController c) {
    return double.tryParse(c.text.trim().replaceAll(',', '.'));
  }

  // ai generation flow
  Future<void> _generateWithAiAndSave() async {
    if (_busy) return;

    final h = _parseNum(_heightCtrl);
    final w = _parseNum(_weightCtrl);

    if (h == null || h <= 0 || w == null || w <= 0) {
      _snack('Please enter valid height and weight.');
      return;
    }

    setState(() => _busy = true);

    try {
      final result = await _generator
          .generate(
            location: _location,
            split: _split,
            goal: _goal,
            heightCm: h,
            weightKg: w,
          )
          .timeout(const Duration(seconds: 40));

      await _repo.saveProgram(
        title: result.title,
        location: _location,
        split: _split,
        goal: _goal,
        heightCm: h,
        weightKg: w,
        daysJson: result.days,
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'currentProgram': {
          'title': result.title,
          'goal': _goal,
          'split': _split,
          'location': _location,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });

      _snack('Program saved successfully');
      _tab.animateTo(1);
    } on TimeoutException {
      _snack('Request timed out. Please try again.');
    } catch (e) {
      _snack('Failed to generate program.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    final pageTheme = base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconTheme: base.iconTheme.copyWith(color: Colors.white),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppTheme.neonPurple,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        dividerColor: Colors.white10,
      ),
    );

    // page layout scaffold
    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Program Builder'),
          bottom: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Create'),
              Tab(text: 'Saved'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: TabBarView(
            controller: _tab,
            children: [_buildCreateTab(), _buildSavedTab()],
          ),
        ),
      ),
    );
  }

  // create tab widgets
  Widget _buildCreateTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _inputCard(),
        const SizedBox(height: 16),
        _choiceCard(
          'Training Location',
          ['Home', 'Gym'],
          _location,
          (v) => setState(() => _location = v),
        ),
        const SizedBox(height: 12),
        _choiceCard(
          'Workout Split',
          ['Push/Pull/Legs', 'Upper/Lower'],
          _split,
          (v) => setState(() => _split = v),
        ),
        const SizedBox(height: 12),
        _choiceCard(
          'Goal',
          ['Strength', 'Fat Loss', 'Conditioning'],
          _goal,
          (v) => setState(() => _goal = v),
        ),
        const SizedBox(height: 20),
        AppButton(
          text: _busy ? 'Generating...' : 'Generate with AI',
          onPressed: _busy ? () {} : _generateWithAiAndSave,
        ),
      ],
    );
  }

  // measurement input card
  Widget _inputCard() {
    return AppCard(
      child: Column(
        children: [
          _numberField('Height (cm)', _heightCtrl),
          const SizedBox(height: 12),
          _numberField('Weight (kg)', _weightCtrl),
        ],
      ),
    );
  }

  Widget _numberField(String label, TextEditingController c) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d*)?$')),
      ],
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        floatingLabelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: AppTheme.surface.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // option selection cards
  Widget _choiceCard(
    String title,
    List<String> items,
    String selected,
    ValueChanged<String> onSelect,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map(
                  (e) => GestureDetector(
                    onTap: () => onSelect(e),
                    child: AppCard(
                      glow: selected == e,
                      glowColor: AppTheme.neonPurple,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          e,
                          style: TextStyle(
                            color: selected == e
                                ? Colors.white
                                : Colors.white.withOpacity(0.80),
                            fontWeight: selected == e
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // saved programs stream
  Widget _buildSavedTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repo.watchPrograms(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No saved programs',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final title = (d['title'] as String?) ?? 'Program';

            return AppCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    (d['goal'] as String?) ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.white,
                      onPressed: () async {
                        final ok = await _confirmDelete(title);
                        if (!ok) return;

                        final uid = FirebaseAuth.instance.currentUser!.uid;

                        await _repo.deleteProgram(docs[i].id);

                        final userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid);
                        final userSnap = await userRef.get();
                        final userData = userSnap.data() ?? {};
                        final current = (userData['currentProgram'] as Map?)
                            ?.cast<String, dynamic>();

                        final currentTitle =
                            (current?['title'] as String?) ?? "";
                        if (currentTitle.isNotEmpty && currentTitle == title) {
                          await userRef.update({
                            'currentProgram': FieldValue.delete(),
                          });
                        }

                        if (context.mounted) {
                          _snack("Program deleted");
                        }
                      },
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProgramDetailPage(
                        title: d['title'],
                        days: (d['days'] as Map).cast<String, dynamic>(),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
