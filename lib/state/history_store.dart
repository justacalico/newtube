import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';
import 'prefs_codec.dart';

class HistoryStore extends ChangeNotifier {
  static const _key = 'history';
  static const _maxEntries = 200;

  final List<VideoInfo> _entries;
  final Map<String, int> _positions;

  HistoryStore([List<VideoInfo>? entries, Map<String, int>? positions])
    : _entries = List.of(entries ?? const []),
      _positions = Map.of(positions ?? const {});

  static const _positionsKey = 'history_positions';

  static Future<HistoryStore> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    final positions = <String, int>{};
    final rawPos = prefs.getString(_positionsKey);
    if (rawPos != null) {
      try {
        final decoded = jsonDecode(rawPos);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (k is String && v is int) positions[k] = v;
          });
        }
      } catch (_) {}
    }
    return HistoryStore(
      decodePrefsList(
        raw,
        (e) => e is Map<String, dynamic> ? VideoInfo.fromJson(e) : null,
      ),
      positions,
    );
  }

  Duration? positionFor(String videoId) {
    final seconds = _positions[videoId];
    return seconds == null ? null : Duration(seconds: seconds);
  }

  Future<void> savePosition(
    String videoId,
    Duration position,
    SharedPreferences prefs,
  ) async {
    _positions[videoId] = position.inSeconds;
    await savePrefsJson(prefs, _positionsKey, _positions);
    notifyListeners();
  }

  Future<void> clearPosition(String videoId, SharedPreferences prefs) async {
    if (_positions.remove(videoId) == null) return;
    await savePrefsJson(prefs, _positionsKey, _positions);
    notifyListeners();
  }

  Future<void> reload(SharedPreferences prefs) async {
    final fresh = await HistoryStore.load(prefs);
    _entries
      ..clear()
      ..addAll(fresh._entries);
    _positions
      ..clear()
      ..addAll(fresh._positions);
    notifyListeners();
  }

  List<VideoInfo> get entries => List.unmodifiable(_entries);

  bool contains(String videoId) => _entries.any((v) => v.id == videoId);

  Future<void> record(VideoInfo video, SharedPreferences prefs) async {
    _entries.removeWhere((v) => v.id == video.id);
    _entries.insert(0, video);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
      final kept = {for (final v in _entries) v.id};
      _positions.removeWhere((id, _) => !kept.contains(id));
      await savePrefsJson(prefs, _positionsKey, _positions);
    }
    await _save(prefs);
    notifyListeners();
  }

  Future<void> remove(String videoId, SharedPreferences prefs) async {
    _entries.removeWhere((v) => v.id == videoId);
    _positions.remove(videoId);
    await _save(prefs);
    await savePrefsJson(prefs, _positionsKey, _positions);
    notifyListeners();
  }

  Future<void> clear(SharedPreferences prefs) async {
    _entries.clear();
    _positions.clear();
    await _save(prefs);
    await savePrefsJson(prefs, _positionsKey, const {});
    notifyListeners();
  }

  Future<void> _save(SharedPreferences prefs) =>
      savePrefsJson(prefs, _key, [for (final v in _entries) v.toJson()]);
}
