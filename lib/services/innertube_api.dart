import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/video_info.dart';
import '../utils/debug_log.dart';
import '../utils/stream_probe.dart';
import 'innertube.dart';
import 'proxy_client.dart';
import 'youtube_api.dart';

class InnertubeApi implements YouTubeApi {
  final http.Client _http;
  final http.Client _probe;
  final String? Function()? _proxyPrefix;

  InnertubeApi({http.Client? httpClient, String? Function()? proxyPrefix})
    : this._(httpClient ?? http.Client(), proxyPrefix);

  InnertubeApi._(http.Client inner, String? Function()? proxyPrefix)
    : _proxyPrefix = proxyPrefix,
      _probe = inner,
      _http = ProxiedClient(inner, () => proxyPrefix?.call());

  String _proxied(String url) => proxiedUrl(url, _proxyPrefix?.call());

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body, {
    String client = 'WEB',
    String? visitorData,
  }) async {
    final response = await _http.post(
      Uri.parse(
        'https://www.youtube.com/youtubei/v1/$endpoint?key=$innertubeKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'context': innertubeContext(client: client, visitorData: visitorData),
        ...body,
      }),
    );
    if (response.statusCode != 200) {
      throw InnertubeException('$endpoint failed with ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw InnertubeException('$endpoint returned invalid body');
    }
    return decoded;
  }

  @override
  Future<List<VideoInfo>> homeFeed() async {
    try {
      final r = await _post('browse', {'browseId': 'FEwhat_to_watch'});
      final videos = <VideoInfo>[];
      collectVideos(r, videos);
      if (videos.isNotEmpty) return _proxiedThumbs(videos);
    } on InnertubeException {
      rethrow;
    } on Object {
      // fall through to search
    }
    final r = await _post('search', {'query': 'popular videos'});
    final videos = <VideoInfo>[];
    collectVideos(r, videos);
    return _proxiedThumbs(videos);
  }

  @override
  Future<SearchResults> search(String query) async {
    final r = await _post('search', {'query': query});
    final videos = <VideoInfo>[];
    final channels = <ChannelInfo>[];
    collectVideos(r, videos);
    collectChannels(r, channels);
    return SearchResults(
      videos: _proxiedThumbs(videos),
      channels: _proxiedChannels(channels),
    );
  }

  @override
  Future<VideoDetails> videoDetails(String videoId) async {
    final r = await _post('player', {
      'videoId': videoId,
      'contentCheckOk': true,
      'racyCheckOk': true,
    }, client: 'ANDROID');
    final details = r['videoDetails'];
    if (details is! Map<String, dynamic>) {
      throw InnertubeException('no videoDetails for $videoId');
    }
    final streaming = r['streamingData'];
    if (streaming is! Map<String, dynamic>) {
      debugLog('[api] $videoId: no streamingData in player response');
    }
    final raw = <PlayableStream>[
      if (streaming is Map<String, dynamic>) ..._streams(streaming),
    ];
    // Stream urls are already prefixed, so probe them with the plain client
    // instead of wrapping them in the proxy prefix a second time.
    var streams = dedupeStreams(await playableStreams(raw, _probe));
    if (raw.any((s) => s.hasVideo && !s.hasAudio) &&
        streams.every((s) => !s.hasVideo || s.hasAudio)) {
      // Adaptive formats exist but every URL failed the probe: YouTube gates
      // them behind a poToken on this video. VISIONOS is exempt as long as the
      // request carries a visitorData session.
      debugLog('[api] $videoId: adaptive streams gated, retrying via VISIONOS');
      final fallback = await _visionosStreaming(videoId);
      if (fallback != null) {
        final extra = await playableStreams(_streams(fallback), _probe);
        streams = dedupeStreams([...streams, ...extra]);
      }
    }
    debugLog('[api] $videoId: ${streams.length} playable streams');
    return VideoDetails(
      info: VideoInfo(
        id: videoId,
        title: details['title'] as String? ?? '',
        author: details['author'] as String? ?? '',
        channelId: details['channelId'] as String? ?? '',
        thumbnailUrl: _thumbField(thumbnail(details['thumbnail'])),
        duration: Duration(
          seconds: int.tryParse(details['lengthSeconds'] as String? ?? '') ?? 0,
        ),
        viewCount: int.tryParse(details['viewCount'] as String? ?? '') ?? 0,
      ),
      description: details['shortDescription'] as String? ?? '',
      streams: streams,
    );
  }

  List<PlayableStream> _streams(Map<String, dynamic> streaming) {
    final out = <PlayableStream>[];
    for (final group in const ['formats', 'adaptiveFormats']) {
      final list = streaming[group];
      if (list is! List) continue;
      for (final format in list) {
        if (format is! Map<String, dynamic>) continue;
        final url = format['url'];
        if (url is! String) continue;
        final mime = format['mimeType'] as String? ?? '';
        final audio = mime.startsWith('audio/');
        final track = format['audioTrack'];
        if (audio &&
            track is Map<String, dynamic> &&
            track['audioIsDefault'] == false) {
          continue;
        }
        final hasAudio = audio || format['audioQuality'] != null;
        final quality = audio
            ? 'audio ${(format['bitrate'] as num? ?? 0).toInt() ~/ 1000}kbps'
            : format['qualityLabel'] as String? ?? 'unknown';
        out.add(
          PlayableStream(
            url: _proxied(url),
            quality: quality,
            hasAudio: hasAudio,
            hasVideo: !audio,
          ),
        );
      }
    }
    return out;
  }

  Future<String?>? _visitor;

  Future<String?> _visitorData() => _visitor ??= _fetchVisitorData().then((v) {
    if (v == null) _visitor = null;
    return v;
  });

  Future<String?> _fetchVisitorData() async {
    try {
      final response = await _http.get(
        Uri.parse('https://www.youtube.com/sw.js_data'),
      );
      if (response.statusCode != 200) return null;
      var text = response.body;
      if (text.startsWith(")]}'")) text = text.substring(4);
      final data = jsonDecode(text);
      if (data is List) {
        final visitor = data[0][2][0][0][13];
        if (visitor is String) return visitor;
      }
    } catch (e) {
      debugLog('[api] visitorData fetch failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _visionosStreaming(String videoId) async {
    final visitor = await _visitorData();
    if (visitor == null) return null;
    try {
      final r = await _post(
        'player',
        {'videoId': videoId, 'contentCheckOk': true, 'racyCheckOk': true},
        client: 'VISIONOS',
        visitorData: visitor,
      );
      final streaming = r['streamingData'];
      if (streaming is Map<String, dynamic>) return streaming;
    } catch (e) {
      debugLog('[api] $videoId: VISIONOS retry failed: $e');
    }
    return null;
  }

  String? _thumbField(String? url) => url == null ? null : _proxied(url);

  List<VideoInfo> _proxiedThumbs(List<VideoInfo> videos, {String? channelId}) =>
      [
        for (final v in videos)
          VideoInfo(
            id: v.id,
            title: v.title,
            author: v.author,
            channelId: v.channelId.isEmpty ? channelId ?? '' : v.channelId,
            thumbnailUrl: _thumbField(v.thumbnailUrl),
            duration: v.duration,
            viewCount: v.viewCount,
            uploaded: v.uploaded,
          ),
      ];

  List<ChannelInfo> _proxiedChannels(List<ChannelInfo> channels) => [
    for (final c in channels)
      ChannelInfo(
        id: c.id,
        name: c.name,
        thumbnailUrl: _thumbField(c.thumbnailUrl),
        subscribers: c.subscribers,
      ),
  ];

  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) async {
    final r = await _post('next', {'videoId': videoId});
    final secondary = _secondaryResults(r);
    final token = secondary == null ? null : continuationToken(secondary);
    final videos = <VideoInfo>[];
    collectVideos(secondary ?? r, videos);
    if (token != null) {
      final cont = await _post('next', {'continuation': token});
      collectVideos(cont, videos);
    }
    return _proxiedThumbs(videos).where((v) => v.id != videoId).toList();
  }

  dynamic _secondaryResults(Map<String, dynamic> r) {
    final contents = r['contents'];
    if (contents is! Map<String, dynamic>) return null;
    final twoColumn = contents['twoColumnWatchNextResults'];
    if (twoColumn is! Map<String, dynamic>) return null;
    final secondary = twoColumn['secondaryResults'];
    if (secondary is Map<String, dynamic>) {
      return secondary['secondaryResults'] ?? secondary;
    }
    return secondary;
  }

  @override
  Future<ChannelInfo> channel(String channelId) async {
    final r = await _post('browse', {'browseId': channelId});
    final metadata = r['metadata'];
    final renderer = metadata is Map<String, dynamic>
        ? metadata['channelMetadataRenderer']
        : null;
    if (renderer is! Map<String, dynamic>) {
      throw InnertubeException('no channelMetadataRenderer for $channelId');
    }
    final header = r['header'];
    return ChannelInfo(
      id: channelId,
      name: renderer['title'] as String? ?? '',
      thumbnailUrl: _thumbField(
        thumbnail(renderer['avatar']) ?? _firstAvatar(header),
      ),
      subscribers: compactCount(_findContaining(header, 'subscriber') ?? ''),
    );
  }

  String? _findContaining(dynamic node, String needle) {
    if (node is Map<String, dynamic>) {
      final content = node['content'];
      if (content is String && content.contains(needle)) {
        return content;
      }
      for (final value in node.values) {
        final found = _findContaining(value, needle);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findContaining(item, needle);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _firstAvatar(dynamic node) {
    if (node is Map<String, dynamic>) {
      final avatar = node['avatar'];
      if (avatar is Map<String, dynamic>) {
        return thumbnail(avatar);
      }
      for (final v in node.values) {
        final found = _firstAvatar(v);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _firstAvatar(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) async {
    final r = await _post('browse', {'browseId': channelId});
    final params = _videosTabParams(r);
    if (params != null) {
      final tab = await _post('browse', {
        'browseId': channelId,
        'params': params,
      });
      final videos = <VideoInfo>[];
      collectVideos(tab, videos);
      if (videos.isNotEmpty) {
        return _proxiedThumbs(videos, channelId: channelId);
      }
    }
    final videos = <VideoInfo>[];
    collectVideos(r, videos);
    return _proxiedThumbs(videos, channelId: channelId);
  }

  String? _videosTabParams(dynamic node) {
    if (node is Map<String, dynamic>) {
      final title = node['title'];
      if (title == 'Videos' || title == 'Video') {
        final endpoint = node['endpoint'];
        if (endpoint is Map<String, dynamic>) {
          final browse = endpoint['browseEndpoint'];
          if (browse is Map<String, dynamic>) {
            final params = browse['params'];
            if (params is String) return params;
          }
        }
      }
      for (final v in node.values) {
        final found = _videosTabParams(v);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _videosTabParams(item);
        if (found != null) return found;
      }
    }
    return null;
  }
}

class InnertubeException implements Exception {
  final String message;
  const InnertubeException(this.message);

  @override
  String toString() => 'InnertubeException: $message';
}
