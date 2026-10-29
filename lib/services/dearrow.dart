import 'dart:convert';

import 'package:http/http.dart' as http;

class DeArrowResult {
  final String? title;
  final String? thumbnailUrl;

  const DeArrowResult({this.title, this.thumbnailUrl});
}

class DeArrowException implements Exception {
  final String message;
  const DeArrowException(this.message);

  @override
  String toString() => 'DeArrowException: $message';
}

class DeArrowClient {
  static const _base = 'https://sponsor.ajay.app';
  static const _thumbBase = 'https://dearrow-thumb.ajay.app';

  final http.Client _client;

  DeArrowClient({http.Client? client}) : _client = client ?? http.Client();

  final _cache = <String, DeArrowResult?>{};

  Future<DeArrowResult?> branding(String videoId) async {
    if (_cache.containsKey(videoId)) return _cache[videoId];
    final response = await _client.get(
      Uri.parse('$_base/api/branding')
          .replace(queryParameters: {'videoID': videoId}),
    );
    if (response.statusCode == 404) return _cache[videoId] = null;
    if (response.statusCode != 200) {
      throw DeArrowException('branding failed with ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return _cache[videoId] = null;
    return _cache[videoId] = DeArrowResult(
      title: _bestTitle(decoded['titles']),
      thumbnailUrl: _bestThumbnail(decoded['thumbnails'], videoId),
    );
  }

  static String? _bestTitle(dynamic raw) {
    if (raw is! List) return null;
    String? best;
    var bestScore = -1;
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final title = entry['title'] as String?;
      if (title == null || title.isEmpty) continue;
      final votes = (entry['votes'] as num? ?? 0).toInt();
      final locked = entry['locked'] == true;
      final score = (locked ? 1 << 20 : 0) + votes;
      if (score > bestScore) {
        bestScore = score;
        best = title;
      }
    }
    return best;
  }

  static String? _bestThumbnail(dynamic raw, String videoId) {
    if (raw is! List) return null;
    double? bestTime;
    var bestScore = -1;
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final timestamp = entry['timestamp'];
      if (timestamp is! num) continue;
      final votes = (entry['votes'] as num? ?? 0).toInt();
      final locked = entry['locked'] == true;
      final score = (locked ? 1 << 20 : 0) + votes;
      if (score > bestScore) {
        bestScore = score;
        bestTime = timestamp.toDouble();
      }
    }
    if (bestTime == null) return null;
    return '$_thumbBase/api/v1/getThumbnail?videoID=$videoId&time=$bestTime';
  }
}
