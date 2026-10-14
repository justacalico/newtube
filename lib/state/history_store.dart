import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';

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
    if (raw == null) return HistoryStore(null, positions);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return HistoryStore(null, positions);
      return HistoryStore([
        for (final e in decoded)
          if (e is Map<String, dynamic>) _decodeVideo(e),
      ], positions);
    } catch (_) {
      return HistoryStore(null, positions);
    }
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
    await prefs.setString(_positionsKey, jsonEncode(_positions));
    notifyListeners();
  }

  Future<void> clearPosition(String videoId, SharedPreferences prefs) async {
    if (_positions.remove(videoId) == null) return;
    await prefs.setString(_positionsKey, jsonEncode(_positions));
    notifyListeners();
  }

  List<VideoInfo> get inProgress => [
    for (final v in _entries)
      if ((_positions[v.id] ?? 0) > 0) v,
  ];

  static VideoInfo _decodeVideo(Map<String, dynamic> json) => VideoInfo(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    author: json['author'] as String? ?? '',
    channelId: json['channelId'] as String? ?? '',
    thumbnailUrl: json['thumbnail'] as String?,
    duration: json['duration'] is int
        ? Duration(seconds: json['duration'] as int)
        : null,
    viewCount: json['views'] as int? ?? 0,
    uploaded: json['uploaded'] as String?,
  );

  List<VideoInfo> get entries => List.unmodifiable(_entries);

  bool contains(String videoId) => _entries.any((v) => v.id == videoId);

  Future<void> record(VideoInfo video, SharedPreferences prefs) async {
    _entries.removeWhere((v) => v.id == video.id);
    _entries.insert(0, video);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    await _save(prefs);
    notifyListeners();
  }

  Future<void> clear(SharedPreferences prefs) async {
    _entries.clear();
    _positions.clear();
    await _save(prefs);
    await prefs.setString(_positionsKey, '{}');
    notifyListeners();
  }

  Future<void> _save(SharedPreferences prefs) => prefs.setString(
    _key,
    jsonEncode([
      for (final v in _entries)
        {
          'id': v.id,
          'title': v.title,
          'author': v.author,
          'channelId': v.channelId,
          'thumbnail': v.thumbnailUrl,
          'duration': v.duration?.inSeconds,
          'views': v.viewCount,
          'uploaded': v.uploaded,
        },
    ]),
  );
}
