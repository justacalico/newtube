import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/search_filter.dart';
import '../models/youtube_route.dart';
import '../models/video_info.dart';
import '../utils/captions.dart';
import '../utils/debug_log.dart';
import '../utils/heatmap.dart';
import '../utils/storyboard.dart';
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
  Future<List<VideoInfo>> trending() async {
    final r = await _post('browse', {'browseId': 'FEtrending'});
    final videos = <VideoInfo>[];
    collectVideos(r, videos);
    return _proxiedThumbs(videos);
  }

  @override
  Future<List<String>> searchSuggestions(String query) async {
    final r = await _post('suggest_queries', {'input': query});
    final suggestions = <String>[];
    void walk(dynamic node) {
      if (node is Map<String, dynamic>) {
        final item = node['querySuggestion'];
        if (item is Map<String, dynamic>) {
          final text = item['text'];
          if (text is String && text.isNotEmpty) suggestions.add(text);
          return;
        }
        for (final value in node.values) {
          walk(value);
        }
      } else if (node is List) {
        for (final item in node) {
          walk(item);
        }
      }
    }

    walk(r);
    return suggestions;
  }

  @override
  Future<SearchResults> search(String query, {SearchFilter? filter}) async {
    final r = await _post('search', {
      'query': query,
      'params': ?filter?.toParams(),
    });
    final videos = <VideoInfo>[];
    final channels = <ChannelInfo>[];
    final playlists = <PlaylistInfo>[];
    collectVideos(r, videos);
    collectChannels(r, channels);
    collectPlaylists(r, playlists);
    return SearchResults(
      videos: _proxiedThumbs(videos),
      channels: _proxiedChannels(channels),
      playlists: playlists,
    );
  }

  @override
  Future<YouTubeRoute?> resolveUrl(String url) async {
    final r = await _post('navigation/resolve_url', {'url': url});
    final endpoint = r['endpoint'];
    if (endpoint is! Map<String, dynamic>) return null;
    final watch = endpoint['watchEndpoint'];
    if (watch is Map<String, dynamic>) {
      final videoId = watch['videoId'] as String?;
      if (videoId == null) return null;
      return YouTubeRoute.video(
        videoId,
        playlistId: watch['playlistId'] as String?,
        startSeconds: watch['startTimeSeconds'] as int? ?? 0,
      );
    }
    final browse = endpoint['browseEndpoint'];
    if (browse is! Map<String, dynamic>) return null;
    final id = browse['browseId'] as String?;
    if (id == null) return null;
    if (id.startsWith('VL') || id.startsWith('PL')) {
      return YouTubeRoute.playlist(id.startsWith('VL') ? id.substring(2) : id);
    }
    return YouTubeRoute.channel(id);
  }

  @override
  Future<PlaylistInfo> playlist(String playlistId) async {
    final browseId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
    final r = await _post('browse', {'browseId': browseId});
    final videos = <VideoInfo>[];
    collectPlaylistVideos(r, videos);
    final header = r['header'];
    final renderer = header is Map<String, dynamic>
        ? header['playlistHeaderRenderer']
        : null;
    final metadata = r['metadata'];
    final meta = metadata is Map<String, dynamic>
        ? metadata['playlistMetadataRenderer']
        : null;
    String? title;
    String author = '';
    var count = 0;
    String? thumb;
    if (renderer is Map<String, dynamic>) {
      title = runs(renderer['title']);
      author = runs(renderer['ownerText']) ?? runs(renderer['byline']) ?? '';
      count = compactCount(runs(renderer['numVideosText']) ?? '');
      thumb = thumbnail(renderer['avatar']);
    }
    title ??= meta is Map<String, dynamic> ? meta['title'] as String? : null;
    return PlaylistInfo(
      id: playlistId,
      title: title ?? '',
      author: author,
      thumbnailUrl: _thumbField(thumb) ?? videos.firstOrNull?.thumbnailUrl,
      videoCount: count == 0 ? videos.length : count,
      videos: _proxiedThumbs(videos),
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
    final kept = await playableStreams(raw, _probe);
    var streams = dedupeStreams(kept.isEmpty ? raw : kept);
    final adaptive = streaming is Map<String, dynamic>
        ? streaming['adaptiveFormats']
        : null;
    final hasAdaptiveVideo =
        adaptive is List &&
        adaptive.any(
          (f) =>
              f is Map<String, dynamic> &&
              !(f['mimeType'] as String? ?? '').startsWith('audio/'),
        );
    if (hasAdaptiveVideo && kept.every((s) => !s.hasVideo || s.hasAudio)) {
      // Adaptive formats exist but no video-only url passed the probe: YouTube
      // gates them behind a poToken on this video. VISIONOS is exempt as long
      // as the request carries a visitorData session.
      debugLog('[api] $videoId: adaptive streams gated, retrying via VISIONOS');
      final fallback = await _visionosStreaming(videoId);
      if (fallback != null) {
        final retry = _streams(fallback);
        final extra = await playableStreams(retry, _probe);
        streams = dedupeStreams([
          ...streams,
          ...(extra.isEmpty ? retry : extra),
        ]);
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
        isLive: details['isLive'] == true,
        isUpcoming: details['isUpcoming'] == true,
      ),
      description: details['shortDescription'] as String? ?? '',
      streams: streams,
      captions: _captionTracks(r['captions']),
      storyboards: _storyboards(r['storyboards']),
      heatmap: parseHeatMarkers(r),
    );
  }

  List<Storyboard> _storyboards(dynamic node) {
    if (node is! Map<String, dynamic>) return const [];
    final renderer = node['playerStoryboardSpecRenderer'];
    if (renderer is! Map<String, dynamic>) return const [];
    final spec = renderer['spec'];
    if (spec is! String) return const [];
    return parseStoryboardSpec(spec);
  }

  List<CaptionTrack> _captionTracks(dynamic node) {
    final tracks = <CaptionTrack>[];
    if (node is! Map<String, dynamic>) return tracks;
    final renderer = node['playerCaptionsTracklistRenderer'];
    if (renderer is! Map<String, dynamic>) return tracks;
    final list = renderer['captionTracks'];
    if (list is! List) return tracks;
    for (final t in list) {
      if (t is! Map<String, dynamic>) continue;
      final url = t['baseUrl'];
      if (url is! String) continue;
      final language = t['languageCode'] as String? ?? '';
      tracks.add(
        CaptionTrack(
          url: url,
          languageCode: language,
          name: runs(t['name']) ?? language,
          isAutoGenerated: t['kind'] == 'asr',
        ),
      );
    }
    return tracks;
  }

  @override
  Future<List<CaptionCue>> captions(CaptionTrack track) async {
    final url = track.url.contains('fmt=') ? track.url : '${track.url}&fmt=vtt';
    final response = await _http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw InnertubeException('captions failed with ${response.statusCode}');
    }
    return parseCaptions(response.body);
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
        final trackMap = track is Map<String, dynamic> ? track : null;
        final hasAudio = audio || format['audioQuality'] != null;
        final quality = audio
            ? 'audio ${(format['bitrate'] as num? ?? 0).toInt() ~/ 1000}kbps'
            : format['qualityLabel'] as String? ?? 'unknown';
        final container = mime.split(';').first.split('/').last.trim();
        out.add(
          PlayableStream(
            url: _proxied(url),
            quality: quality,
            hasAudio: hasAudio,
            hasVideo: !audio,
            container: container.isEmpty ? null : container,
            audioLanguage: (trackMap?['id'] as String?)?.split('.').first,
            audioTrackName: trackMap?['displayName'] as String?,
            isDefaultAudio: trackMap?['audioIsDefault'] != false,
            mimeType: mime.isEmpty ? null : mime,
            bitrate: (format['bitrate'] as num?)?.toInt(),
            width: (format['width'] as num?)?.toInt(),
            height: (format['height'] as num?)?.toInt(),
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
        if (visitor is String && visitor.length > 10) return visitor;
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
      _visitor = null;
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
            isLive: v.isLive,
            isUpcoming: v.isUpcoming,
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
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  }) async {
    var token = continuation;
    if (token == null) {
      final r = await _post('next', {'videoId': videoId});
      token = _commentsContinuation(r);
      if (sort != null) {
        token = _sortContinuation(r, sort.index) ?? token;
      }
      if (token == null) {
        debugLog('[api] $videoId: no comments section');
        return const CommentsResult();
      }
    }
    final r = await _post('next', {'continuation': token});
    return _parseComments(r);
  }

  String? _sortContinuation(dynamic node, int index) {
    if (node is Map<String, dynamic>) {
      final menu = node['sortMenu']?['sortMenuRenderer'];
      if (menu is Map<String, dynamic>) {
        final items = menu['sortItems'];
        if (items is List && index < items.length) {
          final item = items[index];
          if (item is Map<String, dynamic>) {
            return continuationToken(item);
          }
        }
      }
      for (final value in node.values) {
        final found = _sortContinuation(value, index);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _sortContinuation(item, index);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _commentsContinuation(dynamic node) {
    if (node is Map<String, dynamic>) {
      final section = node['itemSectionRenderer'];
      if (section is Map<String, dynamic> &&
          _hasKey(section, 'commentsEntryPointHeaderRenderer')) {
        return continuationToken(section);
      }
      for (final value in node.values) {
        final found = _commentsContinuation(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _commentsContinuation(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  bool _hasKey(dynamic node, String key) {
    if (node is Map<String, dynamic>) {
      if (node.containsKey(key)) return true;
      for (final value in node.values) {
        if (_hasKey(value, key)) return true;
      }
    } else if (node is List) {
      for (final item in node) {
        if (_hasKey(item, key)) return true;
      }
    }
    return false;
  }

  CommentsResult _parseComments(Map<String, dynamic> r) {
    final comments = <CommentInfo>[];
    String? next;
    final endpoints = r['onResponseReceivedEndpoints'];
    if (endpoints is! List) return const CommentsResult();
    for (final endpoint in endpoints) {
      if (endpoint is! Map<String, dynamic>) continue;
      final action =
          endpoint['appendContinuationItemsAction'] ??
          endpoint['reloadContinuationItemsCommand'];
      if (action is! Map<String, dynamic>) continue;
      final items = action['continuationItems'];
      if (items is! List) continue;
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final thread = item['commentThreadRenderer'];
        if (thread is Map<String, dynamic>) {
          final comment = thread['comment'];
          final renderer = comment is Map<String, dynamic>
              ? comment['commentRenderer']
              : null;
          if (renderer is Map<String, dynamic>) {
            comments.add(_parseComment(renderer, thread));
          }
        }
        final reply = item['commentRenderer'];
        if (reply is Map<String, dynamic>) {
          comments.add(_parseComment(reply, const {}));
        }
        final more = item['continuationItemRenderer'];
        if (more is Map<String, dynamic>) {
          next ??= continuationToken(more);
        }
      }
    }
    return CommentsResult(comments: comments, continuation: next);
  }

  CommentInfo _parseComment(
    Map<String, dynamic> r,
    Map<String, dynamic> thread,
  ) {
    final endpoint = r['authorEndpoint'];
    final browse = endpoint is Map<String, dynamic>
        ? endpoint['browseEndpoint']
        : null;
    final badge = r['authorCommentBadge'];
    return CommentInfo(
      author: runs(r['authorText']) ?? '',
      channelId: browse is Map<String, dynamic>
          ? browse['browseId'] as String?
          : null,
      text: runs(r['contentText']) ?? '',
      likeCount: compactCount(runs(r['voteCount']) ?? ''),
      published: runs(r['publishedTimeText']),
      avatarUrl: _thumbField(thumbnail(r['authorThumbnail'])),
      replyCount: _replyCount(thread),
      pinned: r['pinnedCommentBadge'] is Map<String, dynamic>,
      hearted: _iconType(badge) == 'HEART',
      isOwner: r['authorIsChannelOwner'] == true,
      replyContinuation: _replyContinuation(thread),
    );
  }

  String? _replyContinuation(Map<String, dynamic> thread) {
    final replies = thread['replies'];
    if (replies is! Map<String, dynamic>) return null;
    final renderer = replies['commentRepliesRenderer'];
    if (renderer is! Map<String, dynamic>) return null;
    final contents = renderer['contents'];
    if (contents is! List) return null;
    for (final item in contents) {
      if (item is! Map<String, dynamic>) continue;
      final more = item['continuationItemRenderer'];
      if (more is Map<String, dynamic>) return continuationToken(more);
    }
    return null;
  }

  String? _iconType(dynamic node) {
    if (node is Map<String, dynamic>) {
      final type = node['iconType'];
      if (type is String) return type;
      for (final value in node.values) {
        final found = _iconType(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _iconType(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  int _replyCount(dynamic node) {
    if (node is Map<String, dynamic>) {
      final replies = node['viewReplies'];
      if (replies is Map<String, dynamic>) {
        return compactCount(runs(replies['buttonText']) ?? '');
      }
      for (final value in node.values) {
        final found = _replyCount(value);
        if (found > 0) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _replyCount(item);
        if (found > 0) return found;
      }
    }
    return 0;
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
  Future<String?> resolveChannel(String url) async {
    final r = await _post('navigation/resolve_url', {'url': url});
    final endpoint = r['endpoint'];
    if (endpoint is! Map<String, dynamic>) return null;
    final browse = endpoint['browseEndpoint'];
    if (browse is! Map<String, dynamic>) return null;
    final id = browse['browseId'];
    return id is String && id.startsWith('UC') ? id : null;
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
