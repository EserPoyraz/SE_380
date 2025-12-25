import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';

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
  Color _resultColor = Colors.white;

  Future<void> _calculate() async {
    final double? weight =
        double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final double? heightCm =
        double.tryParse(_heightCtrl.text.replaceAll(',', '.'));

    if (weight == null || heightCm == null || heightCm <= 0) return;

    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);

    String category;
    Color color;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = Colors.cyanAccent;
    } else if (bmi < 25) {
      category = 'Normal weight';
      color = AppTheme.neonGreen;
    } else if (bmi < 30) {
      category = 'Overweight';
      color = AppTheme.neonOrange;
    } else {
      category = 'Obesity';
      color = Colors.redAccent;
    }

    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'bmiCategory': category,
      'gender': _gender,
    });

    setState(() {
      _bmi = bmi;
      _category = category;
      _resultColor = color;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('BMI kaydedildi: ${bmi.toStringAsFixed(1)}'),
        ),
      );
    }
  }

  String _genderComment() {
    if (_bmi == null) return '';
    if (_gender == 'Male') {
      return 'Not: Erkeklerde kas oranı yüksek olabilir. Bel çevresi ve kas kütlesi birlikte değerlendirilmelidir.';
    } else {
      return 'Not: Kadınlarda yağ dağılımı farklıdır. Bel/kalça oranı ve yağ yüzdesi daha açıklayıcıdır.';
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('BMI Calculator'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ================= INPUT CARD =================
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Body Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _InputField(
                    controller: _weightCtrl,
                    label: "Weight (kg)",
                  ),
                  const SizedBox(height: 12),

                  _InputField(
                    controller: _heightCtrl,
                    label: "Height (cm)",
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Text("Gender"),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _gender,
                        dropdownColor: AppTheme.surface,
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,        // 🔥 ASIL ÇÖZÜM
                          fontWeight: FontWeight.w600,
                        ),
                        underline: Container(
                          height: 1,
                          color: Colors.white38,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text('Male'),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                      ),

                      const Spacer(),
                      AppButton(
                        text: "Calculate",
                        onPressed: _calculate,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= RESULT CARD =================
            if (_bmi != null)
              AppCard(
                glow: true,
                glowColor: _resultColor,
                child: Column(
                  children: [
                    const Text(
                      "Your BMI",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bmi!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: _resultColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _category!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _resultColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _genderComment(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Uyarı: BMI tek başına vücut kompozisyonunu tam olarak yansıtmaz.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
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

// ================= INPUT FIELD =================
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _InputField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: AppTheme.surface.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
