import 'package:flutter/material.dart';
import 'profile_pill.dart';

class ProfileProgramCard extends StatelessWidget {
  const ProfileProgramCard({super.key, required this.program});

  final dynamic program;

  @override
  Widget build(BuildContext context) {
    String title = "No active program";
    String subtitle = "Generate one from Program Builder";
    String badge = "None";

    if (program is Map) {
      final t = program['title']?.toString();
      if (t != null && t.trim().isNotEmpty) title = t.trim();

      final days = program['days'];
      if (days is List) {
        subtitle = "${days.length} days planned";
      }
      badge = "Active";
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.65))),
              ],
            ),
          ),
          ProfilePill(text: badge),
        ],
      ),
    );
  }
}
