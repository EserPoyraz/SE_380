import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/ai_workout_generator.dart';
import '../services/program_repository.dart';
import 'program_detail_page.dart';

class ProgramBuilderPage extends StatefulWidget {
  const ProgramBuilderPage({super.key});

  @override
  State<ProgramBuilderPage> createState() => _ProgramBuilderPageState();
}

class _ProgramBuilderPageState extends State<ProgramBuilderPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _location = 'Home';
  String _split = 'Push/Pull/Legs';
  String _goal = 'Strength';

  bool _busy = false;

  String _lastTitle = 'AI Program';
  Map<String, dynamic> _lastDays = {};

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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double? _parseNum(TextEditingController c) {
    return double.tryParse(c.text.replaceAll(',', '.'));
  }

  Future<void> _generateWithAiAndSave() async {
    if (_busy) return;

    final h = _parseNum(_heightCtrl);
    final w = _parseNum(_weightCtrl);

    if (h == null || h <= 0 || w == null || w <= 0) {
      _snack('Boy ve kilo gir.');
      return;
    }

    setState(() => _busy = true);

    try {
      debugPrint('AI: generate START');

      final result = await _generator
          .generate(
            location: _location,
            split: _split,
            goal: _goal,
            heightCm: h,
            weightKg: w,
          )
          .timeout(const Duration(seconds: 40));

      debugPrint('AI: generate DONE');

      setState(() {
        _lastTitle = result.title;
        _lastDays = result.days;
      });

      debugPrint('FS: save START');

      await _repo
          .saveProgram(
            title: result.title,
            location: _location,
            split: _split,
            goal: _goal,
            heightCm: h,
            weightKg: w,
            daysJson: result.days,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('FS: save DONE');

      _snack('Program kaydedildi.');
      _tab.animateTo(1);
    } on TimeoutException {
      _snack('Zaman aşımı: İnternet yavaş/servis yanıt vermiyor. Tekrar dene.');
    } catch (e) {
      _snack('AI program üretilemedi: $e');
      debugPrint('ERROR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Oluşturucu'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Oluştur'),
            Tab(text: 'Kayıtlı Programlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildCreateTab(), _buildSavedTab()],
      ),
    );
  }

  Widget _buildCreateTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Boy (cm)'),
          const SizedBox(height: 6),
          TextField(
            controller: _heightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          const Text('Kilo (kg)'),
          const SizedBox(height: 6),
          TextField(
            controller: _weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

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
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Strength'),
                selected: _goal == 'Strength',
                onSelected: (_) => setState(() => _goal = 'Strength'),
              ),
              ChoiceChip(
                label: const Text('Fat Loss'),
                selected: _goal == 'Fat Loss',
                onSelected: (_) => setState(() => _goal = 'Fat Loss'),
              ),
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
              onPressed: _busy ? null : _generateWithAiAndSave,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('AI ile Oluştur ve Kaydet'),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _lastDays.isEmpty
                ? const Center(child: Text('Henüz program yok'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _lastTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildPreviewCards(_lastDays)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProgramDetailPage(
                                title: _lastTitle,
                                days: _lastDays,
                              ),
                            ),
                          );
                        },
                        child: const Text('Detayları Aç'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCards(Map<String, dynamic> days) {
    final entries = days.entries.toList();

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final dayName = entries[i].key;
        final dayObj = (entries[i].value as Map).cast<String, dynamic>();

        final focus = (dayObj['focus'] ?? '').toString();
        final exercises = (dayObj['exercises'] as List? ?? const [])
            .cast<dynamic>();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (focus.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Odak: $focus'),
                ],
                const SizedBox(height: 8),
                ...exercises.take(4).map((e) {
                  final ex = (e as Map).cast<String, dynamic>();
                  final name = (ex['name'] ?? '').toString();
                  final sets = (ex['sets'] ?? '').toString();
                  final reps = (ex['reps'] ?? '').toString();
                  return Text('• $name — $sets x $reps');
                }),
                if (exercises.length > 4) const Text('…'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repo.watchPrograms(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Firestore hata: ${snap.error}'),
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Kayıtlı program yok'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();

            final title = (data['title'] ?? 'Program').toString();
            final days = (data['days'] as Map?)?.cast<String, dynamic>() ?? {};
            final goal = (data['goal'] ?? '').toString();

            return Card(
              child: ListTile(
                title: Text(title),
                subtitle: Text(goal),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProgramDetailPage(title: title, days: days),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _repo.deleteProgram(doc.id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
