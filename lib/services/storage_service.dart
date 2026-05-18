import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/strike_record.dart';
import '../models/weather_conditions.dart';

class StorageService {
  static const String _strikeHistoryKey = 'strike_history';
  static const String _weatherConditionsKey = 'weather_conditions';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveStrikeRecord(StrikeRecord record) async {
    final records = getStrikeHistory();
    records.insert(0, record);
    
    // Keep max 100 records
    if (records.length > 100) {
      records.removeRange(100, records.length);
    }

    final jsonList = records.map((r) => r.toJson()).toList();
    await _prefs.setString(_strikeHistoryKey, jsonEncode(jsonList));
  }

  List<StrikeRecord> getStrikeHistory() {
    final String? jsonString = _prefs.getString(_strikeHistoryKey);
    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => StrikeRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearStrikeHistory() async {
    await _prefs.remove(_strikeHistoryKey);
  }

  Future<void> saveWeatherConditions(WeatherConditions conditions) async {
    await _prefs.setString(
        _weatherConditionsKey, jsonEncode(conditions.toJson()));
  }

  WeatherConditions getWeatherConditions() {
    final String? jsonString = _prefs.getString(_weatherConditionsKey);
    if (jsonString == null) {
      return const WeatherConditions();
    }

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return WeatherConditions.fromJson(jsonMap);
    } catch (e) {
      return const WeatherConditions();
    }
  }
}
