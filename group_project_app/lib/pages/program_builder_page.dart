import 'package:flutter/material.dart';
import '../services/program_generator.dart'; // Logic import
import '../models/exercise.dart'; // Model import

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