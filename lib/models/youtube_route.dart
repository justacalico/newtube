class YouTubeRoute {
  final String? videoId;
  final String? playlistId;
  final String? channelId;
  final int startSeconds;

  const YouTubeRoute._({
    this.videoId,
    this.playlistId,
    this.channelId,
    this.startSeconds = 0,
  });

  const YouTubeRoute.video(
    String videoId, {
    String? playlistId,
    int startSeconds = 0,
  }) : this._(
         videoId: videoId,
         playlistId: playlistId,
         startSeconds: startSeconds,
       );

  const YouTubeRoute.playlist(String playlistId)
    : this._(playlistId: playlistId);

  const YouTubeRoute.channel(String channelId) : this._(channelId: channelId);
}

int _timeParam(String? raw) {
  if (raw == null || raw.isEmpty) return 0;
  final seconds = int.tryParse(raw);
  if (seconds != null) return seconds;
  var total = 0;
  var buffer = '';
  for (final ch in raw.split('')) {
    if (int.tryParse(ch) != null) {
      buffer += ch;
    } else {
      final value = int.tryParse(buffer) ?? 0;
      buffer = '';
      total +=
          value *
          switch (ch) {
            'h' => 3600,
            'm' => 60,
            's' => 1,
            _ => 0,
          };
    }
  }
  return total;
}

bool looksLikeYouTubeLink(String text) {
  var t = text.trim();
  if (t.startsWith('newtube://')) return true;
  if (!t.contains('://')) t = 'https://$t';
  final uri = Uri.tryParse(t);
  if (uri == null) return false;
  final host = uri.host;
  return host == 'youtu.be' ||
      host == 'youtube.com' ||
      host.endsWith('.youtube.com');
}

YouTubeRoute? parseYouTubeLink(String text) {
  var t = text.trim();
  if (t.startsWith('newtube://')) {
    t = 'https://youtube.com/${t.substring(10)}';
  }
  if (!t.contains('://')) t = 'https://$t';
  final uri = Uri.tryParse(t);
  if (uri == null || !looksLikeYouTubeLink(text)) return null;
  final path = uri.pathSegments;
  String? videoId;
  String? playlistId = uri.queryParameters['list'];
  if (uri.host == 'youtu.be' && path.isNotEmpty) {
    videoId = path.first;
  } else if (path.isNotEmpty && path.first == 'watch') {
    videoId = uri.queryParameters['v'];
  } else if (path.isNotEmpty &&
      const {'shorts', 'live', 'embed', 'v'}.contains(path.first) &&
      path.length > 1) {
    videoId = path[1];
  } else if (path.isNotEmpty && path.first == 'playlist') {
    videoId = null;
  } else if (path.isNotEmpty && path.first == 'channel' && path.length > 1) {
    return YouTubeRoute.channel(path[1]);
  } else if (path.isNotEmpty &&
      const {'user', 'c'}.contains(path.first) &&
      path.length > 1) {
    return YouTubeRoute.channel(path[1]);
  } else if (uri.path.startsWith('/@')) {
    return YouTubeRoute.channel('@${uri.path.substring(2).split('/').first}');
  }
  if (videoId != null && videoId.isNotEmpty) {
    return YouTubeRoute.video(
      videoId,
      playlistId: playlistId,
      startSeconds: _timeParam(
        uri.queryParameters['t'] ?? uri.queryParameters['start'],
      ),
    );
  }
  if (playlistId != null && playlistId.isNotEmpty) {
    return YouTubeRoute.playlist(playlistId);
  }
  return null;
}
