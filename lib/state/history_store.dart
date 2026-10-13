import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';

class HistoryStore extends ChangeNotifier {
  static const _key = 'history';
  static const _maxEntries = 200;

  final List<VideoInfo> _entries;

  HistoryStore([List<VideoInfo>? entries])
    : _entries = List.of(entries ?? const []);

  static Future<HistoryStore> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return HistoryStore();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return HistoryStore();
      return HistoryStore([
        for (final e in decoded)
          if (e is Map<String, dynamic>) _decodeVideo(e),
      ]);
    } catch (_) {
      return HistoryStore();
    }
  }

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
    await _save(prefs);
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
