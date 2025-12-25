import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
          buttonText: "Set Kaydet 💪",
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
    return Column(
      mainAxisSize: MainAxisSize.min, // 🔥 OVERFLOW FIX
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        // 🔥 TEXT OVERFLOW FIX
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 🔥 FIXED HEIGHT BUTTON
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(buttonText),
          ),
        ),
      ],
    );
  }
}
