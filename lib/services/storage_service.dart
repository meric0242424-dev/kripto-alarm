import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

class StorageService {
  static const String _alarmsKey = 'saved_alarms';

  static Future<List<PriceAlarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_alarmsKey) ?? [];
    return raw.map((s) => PriceAlarm.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> saveAlarms(List<PriceAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_alarmsKey, raw);
  }

  static Future<void> addAlarm(PriceAlarm alarm) async {
    final alarms = await loadAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
  }

  static Future<void> removeAlarm(String id) async {
    final alarms = await loadAlarms();
    alarms.removeWhere((a) => a.id == id);
    await saveAlarms(alarms);
  }

  static Future<void> updateAlarm(PriceAlarm updated) async {
    final alarms = await loadAlarms();
    final idx = alarms.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      alarms[idx] = updated;
      await saveAlarms(alarms);
    }
  }
}
