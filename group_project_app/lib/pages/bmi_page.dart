import 'package:flutter/material.dart';

class BmiPage extends StatefulWidget {
  // BOY KİLO ORAN SAYFASI
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

  void _calculate() {
    final double? weight = double.tryParse(
      _weightCtrl.text.replaceAll(',', '.'),
    );
    final double? heightCm = double.tryParse(
      _heightCtrl.text.replaceAll(',', '.'),
    );
    if (weight == null || heightCm == null || heightCm <= 0) return;

    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);

    String category;
    if (bmi < 18.5) {
      category = 'Underweight';
    } else if (bmi < 25) {
      category = 'Normal weight';
    } else if (bmi < 30) {
      category = 'Overweight';
    } else {
      category = 'Obesity';
    }

    setState(() {
      _bmi = bmi;
      _category = category;
    });
  }

  String _genderComment() {
    if (_bmi == null) return '';
    if (_gender == 'Male') {
      return 'Not: Erkeklerde kas oranı genelde daha yüksek olabilir — bel çevresi ve kas kütlesine bakmak faydalıdır.';
    } else {
      return 'Not: Kadınlarda yağ oranı farklı olabilir — bel/kalça oranı ve %vücut yağını ölçmek daha açıklayıcı olur.';
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
      appBar: AppBar(title: const Text('BMI Hesaplayıcı')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilo (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Boy (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Cinsiyet:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Erkek')),
                    DropdownMenuItem(value: 'Female', child: Text('Kadın')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Hesapla'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_bmi != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'BMI: ${_bmi!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kategori: $_category',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _genderComment(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Uyarı: BMI tek başına vücut kompozisyonunu göstermez. Ölçümler ve doktor değerlendirmesi önemlidir.',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}