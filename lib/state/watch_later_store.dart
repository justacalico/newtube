import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';

class WatchLaterStore extends ChangeNotifier {
  static const _key = 'watch_later';

  final Map<String, VideoInfo> _videos;

  WatchLaterStore([Map<String, VideoInfo>? videos])
    : _videos = Map.of(videos ?? const {});

  static Future<WatchLaterStore> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return WatchLaterStore();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return WatchLaterStore();
      return WatchLaterStore({
        for (final item in decoded)
          if (item is Map<String, dynamic> && item['id'] is String)
            item['id'] as String: _decode(item),
      });
    } catch (_) {
      return WatchLaterStore();
    }
  }

  static VideoInfo _decode(Map<String, dynamic> json) => VideoInfo(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    author: json['author'] as String? ?? '',
    channelId: json['channelId'] as String? ?? '',
    thumbnailUrl: json['thumbnail'] as String?,
    duration: Duration(seconds: json['duration'] as int? ?? 0),
    viewCount: json['viewCount'] as int? ?? 0,
    uploaded: json['uploaded'] as String?,
  );

  List<VideoInfo> get videos => _videos.values.toList();

  bool contains(String videoId) => _videos.containsKey(videoId);

  Future<void> toggle(VideoInfo video, SharedPreferences prefs) async {
    if (_videos.containsKey(video.id)) {
      _videos.remove(video.id);
    } else {
      _videos[video.id] = video;
    }
    await _save(prefs);
    notifyListeners();
  }

  Future<void> remove(String videoId, SharedPreferences prefs) async {
    _videos.remove(videoId);
    await _save(prefs);
    notifyListeners();
  }

  Future<void> _save(SharedPreferences prefs) => prefs.setString(
    _key,
    jsonEncode([
      for (final v in _videos.values)
        {
          'id': v.id,
          'title': v.title,
          'author': v.author,
          'channelId': v.channelId,
          'thumbnail': v.thumbnailUrl,
          'duration': v.duration?.inSeconds ?? 0,
          'viewCount': v.viewCount,
          'uploaded': v.uploaded,
        },
    ]),
  );
}
