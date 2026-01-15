import 'package:flutter/material.dart';

class ProgramDetailPage extends StatelessWidget {
  final String title;
  final Map<String, dynamic> days;

  const ProgramDetailPage({super.key, required this.title, required this.days});

  @override
  Widget build(BuildContext context) {
    final entries = days.entries.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F1A), Color(0xFF141A2E)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final dayName = entries[i].key;
            final dayObj = (entries[i].value as Map).cast<String, dynamic>();

            final focus = (dayObj['focus'] ?? '').toString();
            final exercises = (dayObj['exercises'] as List? ?? const [])
                .cast<dynamic>();

            return _DayGlassCard(
              dayName: dayName,
              focus: focus,
              exercises: exercises,
            );
          },
        ),
      ),
    );
  }
}

class _DayGlassCard extends StatelessWidget {
  final String dayName;
  final String focus;
  final List<dynamic> exercises;

  const _DayGlassCard({
    required this.dayName,
    required this.focus,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DAY HEADER
          Text(
            dayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (focus.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(focus, style: const TextStyle(color: Colors.white)),
          ],

          const SizedBox(height: 14),

          // EXERCISES
          ...exercises.map((e) {
            final ex = (e as Map).cast<String, dynamic>();
            final name = (ex['name'] ?? '').toString();
            final sets = (ex['sets'] ?? '').toString();
            final reps = (ex['reps'] ?? '').toString();
            final restSec = ex['restSec']?.toString();
            final note = ex['note']?.toString();

            final restText = (restSec != null && restSec.isNotEmpty)
                ? ' • ${restSec}s rest'
                : '';
            final noteText = (note != null && note.isNotEmpty)
                ? ' ($note)'
                : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Text(
                      '$name — $sets x $reps$restText$noteText',
                      style: const TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
