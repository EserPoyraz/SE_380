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
You are a fitness coach. Based on the information below, generate a 3–5 day training program. This program will be for 1 week and the user will repeat it every week. On the days you do not write a workout, write Rest.

Inputs:
- Location: $location
- Split: $split
- Goal: $goal
- Height(cm): $heightCm
- Weight(kg): $weightKg

THE OUTPUT MUST BE JSON ONLY. Do not write anything else.

The JSON format must be EXACTLY like this:
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

Rules:
- Adjust the days according to the split (3–6 days).
- 4–8 exercises per day.
- If Home, write it suitable for home equipment (dumbbell/bodyweight).
- If Gym, it can include barbell/machine as well.
- Keep explanations short.
- Write everything in English. It must be word-for-word English.
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
