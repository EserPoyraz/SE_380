import 'dart:math';
import '../models/exercise.dart';

class ProgramGenerator {
  final String location;
  final String split;
  final String goal;
  final Random _rnd = Random();

  ProgramGenerator({
    required this.location,
    required this.split,
    required this.goal,
  });

  Map<String, List<Exercise>> generate() {
    if (split == 'Push/Pull/Legs') {
      return {'Push': _buildPush(), 'Pull': _buildPull(), 'Legs': _buildLegs()};
    } else {
      return {'Upper': _buildUpper(), 'Lower': _buildLower()};
    }
  }

  int _setsForGoal() {
    switch (goal) {
      case 'Strength':
        return 4;
      default:
        return 3;
    }
  }

  String _repsForGoal(String exerciseType) {
    if (goal == 'Strength') return '4-6';
    if (goal == 'Fat Loss') return '10-15';
    if (goal == 'Conditioning') {
      if (exerciseType == 'cardio') return '30-60s';
      return '12-15';
    }
    return '8-12';
  }

  List<String> _pool(String kind) {
    final home = {
      'pushCompound': [
        'Push-ups',
        'Incline Push-ups',
        'Dumbbell Shoulder Press',
      ],
      'pushAccessory': ['Dips (Bench)', 'Triceps Kickback', 'Pike Push-up'],
      'pullCompound': ['Inverted Row', 'One-arm Dumbbell Row', 'Doorway Row'],
      'pullAccessory': ['Biceps Curl (DB)', 'Hammer Curl', 'Reverse Fly'],
      'legCompound': ['Squats', 'Bulgarian Split Squat', 'Reverse Lunge'],
      'legAccessory': [
        'Hamstring Curl (Swiss Ball)',
        'Calf Raise',
        'Glute Bridge',
      ],
      'conditioning': ['Jumping Jacks', 'Burpees', 'Mountain Climbers'],
    };

    final gym = {
      'pushCompound': [
        'Barbell Bench Press',
        'Seated Dumbbell Press',
        'Incline Bench Press',
      ],
      'pushAccessory': ['Cable Fly', 'Triceps Pushdown', 'Chest Dips'],
      'pullCompound': [
        'Barbell Row',
        'Pull-up/Lat Pulldown',
        'Chest Supported Row',
      ],
      'pullAccessory': ['EZ Bar Curl', 'Face Pull', 'Seated Cable Row (light)'],
      'legCompound': ['Back Squat', 'Deadlift', 'Leg Press'],
      'legAccessory': ['Leg Curl', 'Leg Extension', 'Seated Calf Raise'],
      'conditioning': ['Bike', 'Rowing Machine', 'Treadmill Sprints'],
    };

    final map = location == 'Home' ? home : gym;
    return List<String>.from(map[kind] ?? []);
  }

  List<Exercise> _pick(
    String poolKind,
    int count,
    String type, {
    String? note,
  }) {
    final pool = _pool(poolKind);
    final picked = <Exercise>[];
    final used = <int>{};

    for (var i = 0; i < count && i < pool.length; i++) {
      int idx;
      do {
        idx = _rnd.nextInt(pool.length);
      } while (used.contains(idx) && used.length < pool.length);

      used.add(idx);
      picked.add(
        Exercise(pool[idx], _setsForGoal(), _repsForGoal(type), note: note),
      );
    }
    return picked;
  }

  List<Exercise> _buildPush() {
    final out = <Exercise>[];
    out.addAll(_pick('pushCompound', 2, 'compound'));
    out.addAll(_pick('pushAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Circuit-style'));
    }
    return out;
  }

  List<Exercise> _buildPull() {
    final out = <Exercise>[];
    out.addAll(_pick('pullCompound', 2, 'compound'));
    out.addAll(_pick('pullAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Circuit-style'));
    }
    return out;
  }

  List<Exercise> _buildLegs() {
    final out = <Exercise>[];
    out.addAll(_pick('legCompound', 2, 'compound'));
    out.addAll(_pick('legAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Interval'));
    }
    return out;
  }

  List<Exercise> _buildUpper() {
    final out = <Exercise>[];
    out.addAll(_pick('pushCompound', 1, 'compound'));
    out.addAll(_pick('pullCompound', 1, 'compound'));
    out.addAll(_pick('pushAccessory', 1, 'accessory'));
    out.addAll(_pick('pullAccessory', 1, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Short Circuit'));
    }
    return out;
  }

  List<Exercise> _buildLower() {
    final out = <Exercise>[];
    out.addAll(_pick('legCompound', 2, 'compound'));
    out.addAll(_pick('legAccessory', 2, 'accessory'));
    if (goal == 'Conditioning') {
      out.addAll(_pick('conditioning', 1, 'cardio', note: 'Sled/Intervals'));
    }
    return out;
  }
}
