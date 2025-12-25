import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_card.dart';
import 'app_button.dart';
import '../theme/app_theme.dart';

// ================= NAVIGATION BOX =================
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
      child: AppCard(
        height: 130,
        glow: true,
        glowColor: color,
        child: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

// ================= COUNTER BOX (SETS) =================
class CounterBox extends StatelessWidget {
  final Color color;
  final String userId;

  const CounterBox({
    super.key,
    required this.color,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final int sets = data['sets'] ?? 0;

        return _StatContent(
          title: "Sets",
          value: "$sets",
          buttonText: "Log Set 💪",
          color: color,
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'sets': FieldValue.increment(1),
            });
          },
        );
      },
    );
  }
}

// ================= WATER TRACKER BOX =================
class WaterTrackerBox extends StatelessWidget {
  final Color color;
  final String userId;

  const WaterTrackerBox({
    super.key,
    required this.color,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final int water = data['water'] ?? 0;

        return _StatContent(
          title: "Water",
          value: "$water ml",
          buttonText: "Drink 💧 +200 ml",
          color: color,
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'water': FieldValue.increment(200),
            });
          },
        );
      },
    );
  }
}

// ================= SHARED STAT CONTENT =================
class _StatContent extends StatelessWidget {
  final String title;
  final String value;
  final String buttonText;
  final Color color;
  final VoidCallback onPressed;

  const _StatContent({
    required this.title,
    required this.value,
    required this.buttonText,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      height: 190,
      glow: true,
      glowColor: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),

          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 14),

          AppButton(
            text: buttonText,
            accentColor: color,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
