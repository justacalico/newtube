import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiddenStore extends ChangeNotifier {
  static const _videosKey = 'hidden_videos';
  static const _channelsKey = 'hidden_channels';

  final Set<String> _videos;
  final Set<String> _channels;

  HiddenStore([Set<String>? videos, Set<String>? channels])
    : _videos = Set.of(videos ?? const {}),
      _channels = Set.of(channels ?? const {});

  static Future<HiddenStore> load(SharedPreferences prefs) async => HiddenStore(
    (prefs.getStringList(_videosKey) ?? const []).toSet(),
    (prefs.getStringList(_channelsKey) ?? const []).toSet(),
  );

  Future<void> reload(SharedPreferences prefs) async {
    final fresh = await load(prefs);
    _videos
      ..clear()
      ..addAll(fresh._videos);
    _channels
      ..clear()
      ..addAll(fresh._channels);
    notifyListeners();
  }

  bool isVideoHidden(String id) => _videos.contains(id);
  bool isChannelHidden(String id) => _channels.contains(id);
  Set<String> get videos => Set.unmodifiable(_videos);
  Set<String> get channels => Set.unmodifiable(_channels);

  Future<void> hideVideo(String id, SharedPreferences prefs) async {
    _videos.add(id);
    await prefs.setStringList(_videosKey, _videos.toList());
    notifyListeners();
  }

  Future<void> unhideVideo(String id, SharedPreferences prefs) async {
    _videos.remove(id);
    await prefs.setStringList(_videosKey, _videos.toList());
    notifyListeners();
  }

  Future<void> hideChannel(String id, SharedPreferences prefs) async {
    _channels.add(id);
    await prefs.setStringList(_channelsKey, _channels.toList());
    notifyListeners();
  }

  Future<void> unhideChannel(String id, SharedPreferences prefs) async {
    _channels.remove(id);
    await prefs.setStringList(_channelsKey, _channels.toList());
    notifyListeners();
  }
}
