import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

List<T>? decodePrefsList<T>(String? raw, T? Function(Object? item) decode) {
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    final out = <T>[];
    for (final item in decoded) {
      final value = decode(item);
      if (value != null) out.add(value);
    }
    return out;
  } catch (_) {
    return null;
  }
}

Future<void> savePrefsJson(
  SharedPreferences prefs,
  String key,
  Object? value,
) => prefs.setString(key, jsonEncode(value));
