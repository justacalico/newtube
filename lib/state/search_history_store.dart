import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_codec.dart';

class SearchHistoryStore extends ChangeNotifier {
  static const _key = 'search_history';
  static const _maxEntries = 50;

  final List<String> _entries;

  SearchHistoryStore([List<String>? entries])
    : _entries = List.of(entries ?? const []);

  static Future<SearchHistoryStore> load(SharedPreferences prefs) async =>
      SearchHistoryStore(
        decodePrefsList(prefs.getString(_key), (e) => e is String ? e : null),
      );

  Future<void> reload(SharedPreferences prefs) async {
    final fresh = await SearchHistoryStore.load(prefs);
    _entries
      ..clear()
      ..addAll(fresh._entries);
    notifyListeners();
  }

  List<String> get entries => List.unmodifiable(_entries);

  Future<void> record(String query, SharedPreferences prefs) async {
    _entries.remove(query);
    _entries.insert(0, query);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    await _save(prefs);
    notifyListeners();
  }

  Future<void> remove(String query, SharedPreferences prefs) async {
    _entries.remove(query);
    await _save(prefs);
    notifyListeners();
  }

  Future<void> clear(SharedPreferences prefs) async {
    _entries.clear();
    await _save(prefs);
    notifyListeners();
  }

  Future<void> _save(SharedPreferences prefs) =>
      savePrefsJson(prefs, _key, _entries);
}
