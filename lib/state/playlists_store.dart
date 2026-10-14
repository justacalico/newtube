import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';

class PlaylistsStore extends ChangeNotifier {
  static const _key = 'playlists';

  final List<PlaylistInfo> _playlists;

  PlaylistsStore([List<PlaylistInfo>? playlists])
    : _playlists = List.of(playlists ?? const []);

  static Future<PlaylistsStore> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return PlaylistsStore();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return PlaylistsStore();
      return PlaylistsStore([
        for (final item in decoded)
          if (item is Map<String, dynamic> && item['id'] is String)
            _decode(item),
      ]);
    } catch (_) {
      return PlaylistsStore();
    }
  }

  static PlaylistInfo _decode(Map<String, dynamic> json) {
    final videos = <VideoInfo>[
      for (final item in json['videos'] as List? ?? const [])
        if (item is Map<String, dynamic> && item['id'] is String)
          _decodeVideo(item),
    ];
    return PlaylistInfo(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      thumbnailUrl: json['thumbnail'] as String?,
      videoCount: videos.length,
      videos: videos,
    );
  }

  static VideoInfo _decodeVideo(Map<String, dynamic> json) => VideoInfo(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    author: json['author'] as String? ?? '',
    channelId: json['channelId'] as String? ?? '',
    thumbnailUrl: json['thumbnail'] as String?,
    duration: Duration(seconds: json['duration'] as int? ?? 0),
    viewCount: json['viewCount'] as int? ?? 0,
    uploaded: json['uploaded'] as String?,
  );

  List<PlaylistInfo> get playlists => List.unmodifiable(_playlists);

  PlaylistInfo? byId(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  bool containsVideo(String playlistId, String videoId) =>
      byId(playlistId)?.videos.any((v) => v.id == videoId) ?? false;

  Future<PlaylistInfo> create(String title, SharedPreferences prefs) async {
    final playlist = PlaylistInfo(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
    );
    _playlists.add(playlist);
    await _save(prefs);
    notifyListeners();
    return playlist;
  }

  Future<void> rename(String id, String title, SharedPreferences prefs) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index < 0) return;
    _playlists[index] = PlaylistInfo(
      id: _playlists[index].id,
      title: title,
      author: _playlists[index].author,
      thumbnailUrl: _playlists[index].thumbnailUrl,
      videoCount: _playlists[index].videos.length,
      videos: _playlists[index].videos,
    );
    await _save(prefs);
    notifyListeners();
  }

  Future<void> delete(String id, SharedPreferences prefs) async {
    _playlists.removeWhere((p) => p.id == id);
    await _save(prefs);
    notifyListeners();
  }

  Future<void> toggleSaved(
    PlaylistInfo playlist,
    SharedPreferences prefs,
  ) async {
    if (byId(playlist.id) != null) {
      _playlists.removeWhere((p) => p.id == playlist.id);
    } else {
      _playlists.add(
        PlaylistInfo(
          id: playlist.id,
          title: playlist.title,
          author: playlist.author,
          thumbnailUrl: playlist.thumbnailUrl,
          videoCount: playlist.videos.length,
          videos: playlist.videos,
        ),
      );
    }
    await _save(prefs);
    notifyListeners();
  }

  Future<void> addVideo(
    String id,
    VideoInfo video,
    SharedPreferences prefs,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index < 0 || containsVideo(id, video.id)) return;
    final current = _playlists[index];
    _playlists[index] = PlaylistInfo(
      id: current.id,
      title: current.title,
      author: current.author,
      thumbnailUrl: current.thumbnailUrl ?? video.thumbnailUrl,
      videoCount: current.videos.length + 1,
      videos: [...current.videos, video],
    );
    await _save(prefs);
    notifyListeners();
  }

  Future<void> moveVideo(
    String id,
    int from,
    int to,
    SharedPreferences prefs,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final current = _playlists[index];
    if (from < 0 || from >= current.videos.length) return;
    if (to < 0 || to >= current.videos.length) return;
    final videos = List<VideoInfo>.of(current.videos);
    final moved = videos.removeAt(from);
    videos.insert(to, moved);
    _playlists[index] = PlaylistInfo(
      id: current.id,
      title: current.title,
      author: current.author,
      thumbnailUrl: current.thumbnailUrl,
      videoCount: videos.length,
      videos: videos,
    );
    await _save(prefs);
    notifyListeners();
  }

  Future<void> removeVideo(
    String id,
    String videoId,
    SharedPreferences prefs,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final current = _playlists[index];
    _playlists[index] = PlaylistInfo(
      id: current.id,
      title: current.title,
      author: current.author,
      thumbnailUrl: current.thumbnailUrl,
      videoCount: current.videos.length - 1,
      videos: [
        for (final v in current.videos)
          if (v.id != videoId) v,
      ],
    );
    await _save(prefs);
    notifyListeners();
  }

  Future<void> _save(SharedPreferences prefs) => prefs.setString(
    _key,
    jsonEncode([
      for (final p in _playlists)
        {
          'id': p.id,
          'title': p.title,
          'author': p.author,
          'thumbnail': p.thumbnailUrl,
          'videos': [
            for (final v in p.videos)
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
          ],
        },
    ]),
  );
}
