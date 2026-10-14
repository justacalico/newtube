import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

String exportBackup(SharedPreferences prefs) {
  final data = <String, Object?>{};
  for (final key in prefs.getKeys()) {
    data[key] = prefs.get(key);
  }
  return jsonEncode({'version': 1, 'prefs': data});
}

Future<int> importBackup(String text, SharedPreferences prefs) async {
  final decoded = jsonDecode(text);
  if (decoded is! Map || decoded['prefs'] is! Map) {
    throw const FormatException('not a backup file');
  }
  final data = decoded['prefs'] as Map;
  var count = 0;
  for (final entry in data.entries) {
    final key = entry.key;
    if (key is! String || key.isEmpty) continue;
    final value = entry.value;
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is List) {
      await prefs.setStringList(key, [for (final v in value) '$v']);
    } else {
      continue;
    }
    count++;
  }
  return count;
}
