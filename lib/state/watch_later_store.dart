import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';
import 'prefs_codec.dart';

class WatchLaterStore extends ChangeNotifier {
  static const _key = 'watch_later';

  final Map<String, VideoInfo> _videos;

  WatchLaterStore([Map<String, VideoInfo>? videos])
    : _videos = Map.of(videos ?? const {});

  static Future<WatchLaterStore> load(SharedPreferences prefs) async {
    final entries = decodePrefsList(
      prefs.getString(_key),
      (item) => item is Map<String, dynamic> && item['id'] is String
          ? MapEntry(item['id'] as String, VideoInfo.fromJson(item))
          : null,
    );
    return WatchLaterStore(entries == null ? null : Map.fromEntries(entries));
  }

  Future<void> reload(SharedPreferences prefs) async {
    final fresh = await WatchLaterStore.load(prefs);
    _videos
      ..clear()
      ..addAll(fresh._videos);
    notifyListeners();
  }

  List<VideoInfo> get videos => _videos.values.toList();

  Future<void> move(int from, int to, SharedPreferences prefs) async {
    final entries = _videos.entries.toList();
    if (from < 0 || from >= entries.length) return;
    to = to.clamp(0, entries.length - 1);
    final entry = entries.removeAt(from);
    entries.insert(to, entry);
    _videos
      ..clear()
      ..addEntries(entries);
    await _save(prefs);
    notifyListeners();
  }

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

  Future<void> _save(SharedPreferences prefs) =>
      savePrefsJson(prefs, _key, [for (final v in _videos.values) v.toJson()]);
}
