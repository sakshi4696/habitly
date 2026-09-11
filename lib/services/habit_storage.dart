import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class HabitStorage {
  static const _key = 'habits';

  static Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];

    final List decoded = jsonDecode(data);
    return decoded.map((e) => Habit.fromJson(e)).toList();
  }

  static Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_key, data);
  }
}
