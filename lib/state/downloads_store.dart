import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';

class DownloadEntry {
  final VideoInfo video;
  final String path;
  final int bytes;

  const DownloadEntry({
    required this.video,
    required this.path,
    this.bytes = 0,
  });
}

class DownloadsStore extends ChangeNotifier {
  static const _key = 'downloads';

  final List<DownloadEntry> _entries;

  DownloadsStore([List<DownloadEntry>? entries])
    : _entries = List.of(entries ?? const []);

  static Future<DownloadsStore> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return DownloadsStore();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return DownloadsStore();
      return DownloadsStore([
        for (final e in decoded)
          if (e is Map<String, dynamic>)
            DownloadEntry(
              video: VideoInfo(
                id: e['id'] as String? ?? '',
                title: e['title'] as String? ?? '',
                author: e['author'] as String? ?? '',
                channelId: e['channelId'] as String? ?? '',
                thumbnailUrl: e['thumbnail'] as String?,
                duration: e['duration'] is int
                    ? Duration(seconds: e['duration'] as int)
                    : null,
              ),
              path: e['path'] as String? ?? '',
              bytes: e['bytes'] as int? ?? 0,
            ),
      ]);
    } catch (_) {
      return DownloadsStore();
    }
  }

  List<DownloadEntry> get entries => List.unmodifiable(_entries);

  Future<void> add(DownloadEntry entry, SharedPreferences prefs) async {
    _entries.removeWhere((e) => e.video.id == entry.video.id);
    _entries.insert(0, entry);
    await _save(prefs);
    notifyListeners();
  }

  Future<void> remove(String videoId, SharedPreferences prefs) async {
    _entries.removeWhere((e) => e.video.id == videoId);
    await _save(prefs);
    notifyListeners();
  }

  Future<void> _save(SharedPreferences prefs) => prefs.setString(
    _key,
    jsonEncode([
      for (final e in _entries)
        {
          'id': e.video.id,
          'title': e.video.title,
          'author': e.video.author,
          'channelId': e.video.channelId,
          'thumbnail': e.video.thumbnailUrl,
          'duration': e.video.duration?.inSeconds,
          'path': e.path,
          'bytes': e.bytes,
        },
    ]),
  );
}
