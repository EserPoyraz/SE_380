import 'package:flutter/material.dart';

class ProgramDetailPage extends StatelessWidget {
  final String title;
  final Map<String, dynamic> days;

  const ProgramDetailPage({super.key, required this.title, required this.days});

  @override
  Widget build(BuildContext context) {
    final entries = days.entries.toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final dayName = entries[i].key;
          final dayObj = (entries[i].value as Map).cast<String, dynamic>();

          final focus = (dayObj['focus'] ?? '').toString();
          final exercises = (dayObj['exercises'] as List? ?? const [])
              .cast<dynamic>();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (focus.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Odak: $focus'),
                  ],
                  const SizedBox(height: 10),
                  ...exercises.map((e) {
                    final ex = (e as Map).cast<String, dynamic>();
                    final name = (ex['name'] ?? '').toString();
                    final sets = (ex['sets'] ?? '').toString();
                    final reps = (ex['reps'] ?? '').toString();
                    final restSec = ex['restSec']?.toString();
                    final note = ex['note']?.toString();

                    final restText = (restSec != null && restSec.isNotEmpty)
                        ? ' • Dinlenme: ${restSec}s'
                        : '';
                    final noteText = (note != null && note.isNotEmpty)
                        ? ' ($note)'
                        : '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('$name — $sets x $reps$restText$noteText'),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
