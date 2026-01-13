import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

class GeneratedProgram {
  final String title;
  final Map<String, dynamic> days;

  GeneratedProgram({required this.title, required this.days});
}

class AiWorkoutGenerator {
  const AiWorkoutGenerator();

  Future<GeneratedProgram> generate({
    required String location,
    required String split,
    required String goal,
    required double heightCm,
    required double weightKg,
  }) async {
    // JSON garanti etmek için config’li model
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt =
        '''
Sen bir fitness koçusun. Aşağıdaki bilgilere göre 3-6 günlük antrenman programı üret. Bu program 1 haftalık olacak ve kullanıcı her hafta tekrar edecek.

Girdiler:
- Konum: $location
- Split: $split
- Hedef: $goal
- Boy(cm): $heightCm
- Kilo(kg): $weightKg

ÇIKTI SADECE JSON OLACAK. Başka hiçbir şey yazma.

JSON formatı TAM olarak şöyle olmalı:
{
  "title": "string",
  "days": {
    "Day 1": {
      "focus": "string",
      "exercises": [
        {"name":"string","sets":3,"reps":"8-12","restSec":90,"note":"optional"}
      ]
    }
  }
}

Kurallar:
- Split'e göre günleri ayarla (3-6 gün).
- Gün başına 4-8 egzersiz.
- Home ise ev ekipmanına uygun yaz (dumbbell/bodyweight).
- Gym ise barbell/machine da olabilir.
- Açıklamalar kısa olsun.
- Herşeyi ingilizce yaz. Kelimesi kelimesine ingilizce olmak zorunda.
''';

    final response = await model.generateContent([Content.text(prompt)]);

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw Exception('AI boş cevap döndürdü.');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('JSON decode hatası. Gelen cevap: $text');
    }

    final title = (data['title'] ?? 'AI Program').toString();
    final days = (data['days'] as Map?)?.cast<String, dynamic>();

    if (days == null || days.isEmpty) {
      throw Exception('JSON içinde "days" yok ya da boş.');
    }

    return GeneratedProgram(title: title, days: days);
  }
}
