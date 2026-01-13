import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';

enum UnitSystem { metric, imperial }

class BmiPage extends StatefulWidget {
  const BmiPage({super.key});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  // basic input controllers
  final TextEditingController _weightCtrl = TextEditingController(); // kg or lb
  final TextEditingController _heightCmCtrl = TextEditingController(); // cm
  final TextEditingController _heightFtCtrl =
      TextEditingController(); // ft (imperial)
  final TextEditingController _heightInCtrl =
      TextEditingController(); // in (imperial)

  // basic selections state
  String _gender = 'Male';
  UnitSystem _unit = UnitSystem.metric;

  // advanced section controls
  bool _showAdvanced = false;
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _waistCtrl = TextEditingController(); // cm
  final TextEditingController _hipCtrl = TextEditingController(); // cm
  final TextEditingController _neckCtrl = TextEditingController(); // cm

  // activity for tdee
  String _activity = 'Sedentary';
  static const Map<String, double> _activityFactor = {
    'Sedentary': 1.2,
    'Lightly active': 1.375,
    'Moderately active': 1.55,
    'Very active': 1.725,
    'Extra active': 1.9,
  };

  // computed result values
  double? _bmi;
  String? _category;
  Color _resultColor = Colors.white;

  // advanced computed metrics
  double? _bodyFatPct;
  String? _bodyFatCategory;
  double? _bmr;
  double? _tdee;
  double? _whr;
  double? _whtr;

  // safe number parsing
  double? _parseNum(TextEditingController c) {
    return double.tryParse(c.text.trim().replaceAll(',', '.'));
  }

  // normalize height to cm
  double? _metricHeightCm() {
    if (_unit == UnitSystem.metric) {
      return _parseNum(_heightCmCtrl);
    } else {
      final ft = _parseNum(_heightFtCtrl);
      final inch = _parseNum(_heightInCtrl);
      if (ft == null) return null;
      final totalIn = (ft * 12) + (inch ?? 0);
      return totalIn * 2.54;
    }
  }

  // normalize weight to kg
  double? _metricWeightKg() {
    final w = _parseNum(_weightCtrl);
    if (w == null) return null;
    if (_unit == UnitSystem.metric) return w;
    return w * 0.45359237; // lb -> kg
  }

  // bmi category labeling
  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obesity';
  }

  // category color mapping
  Color _categoryColor(double bmi) {
    if (bmi < 18.5) return Colors.cyanAccent;
    if (bmi < 25) return AppTheme.neonGreen;
    if (bmi < 30) return AppTheme.neonOrange;
    return Colors.redAccent;
  }

  String? _bodyFatLabel(String gender, double bf) {
    if (gender == 'Male') {
      if (bf < 6) return 'essential fat';
      if (bf < 14) return 'athletes';
      if (bf < 18) return 'fitness';
      if (bf < 25) return 'average';
      return 'obese';
    } else {
      if (bf < 14) return 'essential fat';
      if (bf < 21) return 'athletes';
      if (bf < 25) return 'fitness';
      if (bf < 32) return 'average';
      return 'obese';
    }
  }

  // body fat estimate formula
  double? _estimateBodyFatPct({
    required String gender,
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double? hipCm,
  }) {
    // US Navy method requires inches
    final h = heightCm / 2.54;
    final w = waistCm / 2.54;
    final n = neckCm / 2.54;
    final hip = hipCm != null ? hipCm / 2.54 : null;

    // log safety helpers
    double log10(num x) => math.log(x) / math.ln10;

    if (gender == 'Male') {
      final a = (w - n);
      if (a <= 0 || h <= 0) return null;
      final bf = 86.010 * log10(a) - 70.041 * log10(h) + 36.76;
      return bf.isFinite ? bf : null;
    } else {
      if (hip == null) return null;
      final a = (w + hip - n);
      if (a <= 0 || h <= 0) return null;
      final bf = 163.205 * log10(a) - 97.684 * log10(h) - 78.387;
      return bf.isFinite ? bf : null;
    }
  }

  // bmr calculation method
  double? _calcBmr({
    required String gender,
    required int age,
    required double weightKg,
    required double heightCm,
  }) {
    // Mifflin-St Jeor
    if (age <= 0 || weightKg <= 0 || heightCm <= 0) return null;
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return gender == 'Male' ? (base + 5) : (base - 161);
  }

  // compute and persist
  Future<void> _calculate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surface.withOpacity(0.95),
            content: const Text(
              'Please sign in to save BMI.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      return;
    }

    final weightKg = _metricWeightKg();
    final heightCm = _metricHeightCm();

    // basic input validation
    if (weightKg == null ||
        heightCm == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surface.withOpacity(0.95),
            content: const Text(
              'Please enter valid height & weight.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      return;
    }

    // primary bmi compute
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    final category = _bmiCategory(bmi);
    final color = _categoryColor(bmi);

    // read advanced inputs
    final int? age = _parseNum(_ageCtrl)?.round();
    final double? waistCm = _parseNum(_waistCtrl);
    final double? hipCm = _parseNum(_hipCtrl);
    final double? neckCm = _parseNum(_neckCtrl);

    double? whr;
    double? whtr;
    double? bodyFat;
    String? bodyFatCategory;
    double? bmr;
    double? tdee;

    // ratio computations
    if (waistCm != null && waistCm > 0) {
      whtr = waistCm / heightCm;
      if (hipCm != null && hipCm > 0) {
        whr = waistCm / hipCm;
      }
    }

    // body fat estimation
    if (_gender == 'Male') {
      if (waistCm != null && waistCm > 0 && neckCm != null && neckCm > 0) {
        bodyFat = _estimateBodyFatPct(
          gender: _gender,
          heightCm: heightCm,
          waistCm: waistCm,
          neckCm: neckCm,
          hipCm: null,
        );
      }
    } else {
      if (waistCm != null &&
          waistCm > 0 &&
          neckCm != null &&
          neckCm > 0 &&
          hipCm != null &&
          hipCm > 0) {
        bodyFat = _estimateBodyFatPct(
          gender: _gender,
          heightCm: heightCm,
          waistCm: waistCm,
          neckCm: neckCm,
          hipCm: hipCm,
        );
      }
    }

    if (bodyFat != null) {
      bodyFatCategory = _bodyFatLabel(_gender, bodyFat);
    }

    // bmr and tdee calc
    if (age != null && age > 0) {
      bmr = _calcBmr(
        gender: _gender,
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
      );
      if (bmr != null) {
        tdee = bmr * (_activityFactor[_activity] ?? 1.2);
      }
    }

    // firestore update payload
    final Map<String, dynamic> payload = {
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'bmiCategory': category,
      'gender': _gender,

      // normalized metric storage
      'heightCm': heightCm.round(),
      'weightKg': weightKg.round(),

      // ui restore raw inputs
      'unitSystem': _unit.name,
      if (_unit == UnitSystem.metric) 'inputHeightCm': _parseNum(_heightCmCtrl),
      if (_unit == UnitSystem.imperial)
        'inputHeightFt': _parseNum(_heightFtCtrl),
      if (_unit == UnitSystem.imperial)
        'inputHeightIn': _parseNum(_heightInCtrl),
      'inputWeight': _parseNum(_weightCtrl),

      // advanced inputs storage
      if (age != null && age > 0) 'age': age,
      if (waistCm != null && waistCm > 0) 'waistCm': waistCm.round(),
      if (_gender == 'Female' && hipCm != null && hipCm > 0)
        'hipCm': hipCm.round(),
      if (neckCm != null && neckCm > 0) 'neckCm': neckCm.round(),
      'activityLevel': _activity,

      // derived advanced storage
      if (bodyFat != null)
        'bodyFatPct': double.parse(bodyFat.toStringAsFixed(1)),
      if (bodyFatCategory != null) 'bodyFatCategory': bodyFatCategory,
      if (bmr != null) 'bmr': double.parse(bmr.toStringAsFixed(0)),
      if (tdee != null) 'tdee': double.parse(tdee.toStringAsFixed(0)),
      if (_gender == 'Female' && whr != null)
        'waistHipRatio': double.parse(whr.toStringAsFixed(2)),
      if (whtr != null)
        'waistHeightRatio': double.parse(whtr.toStringAsFixed(2)),

      'updatedAt': FieldValue.serverTimestamp(),
    };

    // merge into user doc
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(payload, SetOptions(merge: true));

    // update ui state
    setState(() {
      _bmi = bmi;
      _category = category;
      _resultColor = color;

      _bodyFatPct = bodyFat;
      _bodyFatCategory = bodyFatCategory;
      _bmr = bmr;
      _tdee = tdee;
      _whr = whr;
      _whtr = whtr;
    });

    // show saved snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surface.withOpacity(0.95),
          content: Text(
            'Saved. BMI: ${bmi.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  // short gender note
  String _genderComment() {
    if (_bmi == null) return '';
    if (_gender == 'Male') {
      return 'Note: Men may have higher muscle mass. Consider waist circumference and body fat %.';
    } else {
      return 'Note: Fat distribution differs in women. Waist-to-hip ratio and body fat % can help.';
    }
  }

  @override
  void dispose() {
    // dispose all controllers
    _weightCtrl.dispose();
    _heightCmCtrl.dispose();
    _heightFtCtrl.dispose();
    _heightInCtrl.dispose();

    _ageCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _neckCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMetric = _unit == UnitSystem.metric;
    final base = Theme.of(context);

    final pageTheme = base.copyWith(
      brightness: Brightness.dark,
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconTheme: base.iconTheme.copyWith(color: Colors.white70),
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
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppTheme.surface.withOpacity(0.65),
        selectedColor: AppTheme.neonPurple.withOpacity(0.35),
        disabledColor: AppTheme.surface.withOpacity(0.35),
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        checkmarkColor: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: Colors.white12)),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return Colors.white70;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppTheme.neonGreen.withOpacity(0.45);
          }
          return Colors.white24;
        }),
      ),
    );

    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('BMI Calculator')),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // basic input card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Basic",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // unit selection row
                    Row(
                      children: [
                        const Text(
                          "Units",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Metric'),
                          selected: isMetric,
                          onSelected: (_) =>
                              setState(() => _unit = UnitSystem.metric),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Imperial'),
                          selected: !isMetric,
                          onSelected: (_) =>
                              setState(() => _unit = UnitSystem.imperial),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // weight input field
                    _NumberField(
                      controller: _weightCtrl,
                      label: isMetric ? "Weight (kg)" : "Weight (lb)",
                    ),
                    const SizedBox(height: 12),

                    // height input fields
                    if (isMetric) ...[
                      _NumberField(
                        controller: _heightCmCtrl,
                        label: "Height (cm)",
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              controller: _heightFtCtrl,
                              label: "Height (ft)",
                              allowDecimal: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              controller: _heightInCtrl,
                              label: "Height (in)",
                              allowDecimal: true,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // gender and calculate
                    Row(
                      children: [
                        const Text(
                          "Gender",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _gender,
                          dropdownColor: AppTheme.surface,
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(
                            color: Colors.white,
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
                          onChanged: (v) => setState(() {
                            _gender = v ?? 'Male';
                            if (_gender == 'Male') _hipCtrl.clear();
                          }),
                        ),
                        const Spacer(),
                        AppButton(text: "Calculate", onPressed: _calculate),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // advanced toggle switch
              SwitchListTile(
                value: _showAdvanced,
                onChanged: (v) => setState(() => _showAdvanced = v),
                activeColor: AppTheme.neonGreen,
                title: const Text(
                  'Advanced',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Age, circumferences, activity level (optional)',
                  style: TextStyle(color: Colors.white60),
                ),
              ),

              // advanced input card
              if (_showAdvanced)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Advanced Inputs",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // age for bmr
                      _NumberField(
                        controller: _ageCtrl,
                        label: "Age (years)",
                        allowDecimal: false,
                      ),
                      const SizedBox(height: 12),

                      // waist for ratios
                      _NumberField(controller: _waistCtrl, label: "Waist (cm)"),
                      const SizedBox(height: 12),

                      // hip for female bf
                      if (_gender == 'Female') ...[
                        _NumberField(
                          controller: _hipCtrl,
                          label:
                              "Hip (cm) (needed for Female body fat estimate)",
                        ),
                        const SizedBox(height: 12),
                      ],

                      // neck for bf calc
                      _NumberField(
                        controller: _neckCtrl,
                        label: "Neck (cm) (for body fat estimate)",
                      ),
                      const SizedBox(height: 14),

                      // activity multiplier select
                      Row(
                        children: [
                          const Text(
                            "Activity",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _activity,
                              isExpanded: true,
                              dropdownColor: AppTheme.surface,
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              underline: Container(
                                height: 1,
                                color: Colors.white38,
                              ),
                              items: _activityFactor.keys
                                  .map(
                                    (k) => DropdownMenuItem(
                                      value: k,
                                      child: Text(k),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _activity = v ?? 'Sedentary'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "Advanced outputs are estimates. BMI is still shown as the primary metric.",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // results display card
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
                      const SizedBox(height: 14),

                      // advanced results section
                      if (_bodyFatPct != null ||
                          _bmr != null ||
                          _tdee != null ||
                          _whr != null ||
                          _whtr != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),
                            const Text(
                              "Advanced Results",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_bodyFatPct != null)
                              _ResultRow(
                                label: "Body Fat % (estimate)",
                                value: "${_bodyFatPct!.toStringAsFixed(1)}%",
                              ),
                            if (_bodyFatCategory != null)
                              _ResultRow(
                                label: "Body Fat category",
                                value: _bodyFatCategory!,
                              ),
                            if (_bmr != null)
                              _ResultRow(
                                label: "BMR (kcal/day)",
                                value: _bmr!.toStringAsFixed(0),
                              ),
                            if (_tdee != null)
                              _ResultRow(
                                label: "TDEE (kcal/day)",
                                value: _tdee!.toStringAsFixed(0),
                              ),
                            if (_whtr != null)
                              _ResultRow(
                                label: "Waist/Height",
                                value: _whtr!.toStringAsFixed(2),
                              ),
                            if (_gender == 'Female' && _whr != null)
                              _ResultRow(
                                label: "Waist/Hip",
                                value: _whr!.toStringAsFixed(2),
                              ),
                          ],
                        ),

                      const SizedBox(height: 10),
                      const Text(
                        "Disclaimer: BMI does not fully represent body composition.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// numeric input component
class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool allowDecimal;

  const _NumberField({
    required this.controller,
    required this.label,
    this.allowDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = allowDecimal
        ? FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d*)?$'))
        : FilteringTextInputFormatter.digitsOnly;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [formatter],
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        floatingLabelStyle: const TextStyle(color: Colors.white),
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

// result row widget
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
