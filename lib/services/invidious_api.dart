import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/search_filter.dart';
import '../models/video_info.dart';
import '../models/youtube_route.dart';
import '../utils/captions.dart';
import 'youtube_api.dart';

class InvidiousApi implements YouTubeApi {
  final http.Client _client;
  final String instance;

  InvidiousApi({required this.instance, http.Client? client})
    : _client = client ?? http.Client();

  Uri _url(String path, [Map<String, String>? params]) =>
      Uri.parse('${instance.replaceAll(RegExp(r'/\$'), '')}$path')
          .replace(queryParameters: params);

  Future<dynamic> _get(String path, [Map<String, String>? params]) async {
    final response = await _client.get(_url(path, params));
    if (response.statusCode != 200) {
      throw InvidiousException('$path failed with ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  static int? _num(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _thumbOf(dynamic node) {
    final thumbs = node is Map<String, dynamic>
        ? node['videoThumbnails']
        : null;
    if (thumbs is List && thumbs.isNotEmpty) {
      final mid = thumbs.firstWhere(
        (t) => t is Map && t['quality'] == 'medium',
        orElse: () => thumbs[thumbs.length ~/ 2],
      );
      if (mid is Map<String, dynamic> && mid['url'] is String) {
        var url = mid['url'] as String;
        if (url.startsWith('//')) url = 'https:$url';
        return url;
      }
    }
    return '';
  }

  static VideoInfo _video(dynamic node) {
    if (node is! Map<String, dynamic>) {
      return const VideoInfo(id: '', title: '', author: '', channelId: '');
    }
    final id = node['videoId'] as String? ?? '';
    final seconds = _num(node['lengthSeconds']) ?? 0;
    return VideoInfo(
      id: id,
      title: node['title'] as String? ?? '',
      author: node['author'] as String? ?? '',
      channelId: node['authorId'] as String? ?? '',
      thumbnailUrl: _thumbOf(node),
      duration: Duration(seconds: seconds),
      viewCount: _num(node['viewCount']) ?? 0,
      uploaded: node['publishedText'] as String?,
      isLive: node['liveNow'] == true,
      isShort:
          id.isNotEmpty &&
          (node['type'] == 'shortVideo' ||
              ((seconds > 0 && seconds <= 60) &&
                  (node['title'] as String? ?? '').startsWith('#'))),
    );
  }

  static List<VideoInfo> _videos(dynamic body) {
    final out = <VideoInfo>[];
    if (body is List) {
      for (final item in body) {
        final v = _video(item);
        if (v.id.isNotEmpty) out.add(v);
      }
    }
    return out;
  }

  @override
  Future<List<VideoInfo>> homeFeed() => trending();

  @override
  Future<List<VideoInfo>> trending() async =>
      _videos(await _get('/api/v1/trending'));

  @override
  Future<SearchResults> search(String query, {SearchFilter? filter}) async {
    final body = await _get('/api/v1/search', {'q': query, 'type': 'search'});
    final videos = <VideoInfo>[];
    final channels = <ChannelInfo>[];
    final playlists = <PlaylistInfo>[];
    if (body is List) {
      for (final item in body) {
        if (item is! Map<String, dynamic>) continue;
        switch (item['type']) {
          case 'video':
            final v = _video(item);
            if (v.id.isNotEmpty) videos.add(v);
          case 'channel':
            channels.add(
              ChannelInfo(
                id: item['authorId'] as String? ?? '',
                name: item['author'] as String? ?? '',
                subscribers: _num(item['subCount']),
              ),
            );
          case 'playlist':
            playlists.add(
              PlaylistInfo(
                id: item['playlistId'] as String? ?? '',
                title: item['title'] as String? ?? '',
                author: item['author'] as String? ?? '',
                videoCount: _num(item['videoCount']) ?? 0,
                videos: _videos(item['videos']),
              ),
            );
        }
      }
    }
    return SearchResults(
      videos: videos,
      channels: channels,
      playlists: playlists,
    );
  }

  @override
  Future<YouTubeRoute?> resolveUrl(String url) async => parseYouTubeLink(url);

  @override
  Future<List<String>> searchSuggestions(String query) async {
    final body = await _get('/api/v1/search/suggestions', {'q': query});
    if (body is Map<String, dynamic> && body['suggestions'] is List) {
      return [
        for (final s in body['suggestions'] as List)
          if (s is String) s,
      ];
    }
    return const [];
  }

  @override
  Future<VideoDetails> videoDetails(String videoId) async {
    final body = await _get('/api/v1/videos/$videoId');
    if (body is! Map<String, dynamic>) {
      throw InvidiousException('no video data for $videoId');
    }
    final streams = <PlayableStream>[];
    for (final group in const ['formatStreams', 'adaptiveFormats']) {
      final list = body[group];
      if (list is! List) continue;
      for (final f in list) {
        if (f is! Map<String, dynamic>) continue;
        final url = f['url'] as String?;
        if (url == null) continue;
        final mime = f['type'] as String? ?? '';
        final audio = mime.startsWith('audio/');
        streams.add(
          PlayableStream(
            url: url,
            quality: audio
                ? 'audio ${(_num(f['bitrate']) ?? 0) ~/ 1000}kbps'
                : f['qualityLabel'] as String? ?? 'unknown',
            hasAudio:
                audio || f['audioQuality'] != null || group == 'formatStreams',
            hasVideo: !audio,
            container: mime.split(';').first.split('/').last.trim(),
            mimeType: mime.isEmpty ? null : mime,
            bitrate: _num(f['bitrate']),
            height: (f['size'] as String?) != null
                ? int.tryParse((f['size'] as String).split('x').last)
                : null,
          ),
        );
      }
    }
    final captions = <CaptionTrack>[
      for (final c in body['captions'] is List ? body['captions'] as List : [])
        if (c is Map<String, dynamic>)
          CaptionTrack(
            url:
                '$instance/api/v1/captions/$videoId?label=${Uri.encodeComponent(c['label'] as String? ?? '')}',
            languageCode: c['languageCode'] as String? ?? '',
            name: c['label'] as String? ?? '',
          ),
    ];
    return VideoDetails(
      info: VideoInfo(
        id: videoId,
        title: body['title'] as String? ?? '',
        author: body['author'] as String? ?? '',
        channelId: body['authorId'] as String? ?? '',
        thumbnailUrl: _thumbOf(body),
        duration: Duration(seconds: _num(body['lengthSeconds']) ?? 0),
        viewCount: _num(body['viewCount']) ?? 0,
        uploaded: body['publishedText'] as String?,
      ),
      description: body['description'] as String? ?? '',
      streams: streams,
      captions: captions,
    );
  }

  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) async {
    final body = await _get('/api/v1/videos/$videoId');
    if (body is Map<String, dynamic>) {
      return _videos(body['recommendedVideos']);
    }
    return const [];
  }

  @override
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  }) async {
    final body = await _get('/api/v1/comments/$videoId', {
      'continuation': ?continuation,
      if (sort != null) 'sort_by': sort == CommentSort.top ? 'top' : 'new',
    });
    if (body is! Map<String, dynamic>) return const CommentsResult();
    final comments = <CommentInfo>[
      for (final c in body['comments'] is List ? body['comments'] as List : [])
        if (c is Map<String, dynamic>)
          CommentInfo(
            author: c['author'] as String? ?? '',
            channelId: c['authorId'] as String?,
            text: c['content'] as String? ?? '',
            likeCount: _num(c['likeCount']) ?? 0,
            published: c['publishedText'] as String?,
            replyCount: (c['replies'] is Map<String, dynamic>)
                ? (_num(c['replies']['replyCount']) ?? 0)
                : 0,
          ),
    ];
    return CommentsResult(
      comments: comments,
      continuation: body['continuation'] as String?,
    );
  }

  @override
  Future<List<VideoInfo>> channelShorts(String channelId) async =>
      _videos(await _get('/api/v1/channels/$channelId/shorts'));

  @override
  Future<List<PlaylistInfo>> channelPlaylists(String channelId) async {
    final body = await _get('/api/v1/channels/$channelId/playlists');
    if (body is Map<String, dynamic> && body['playlists'] is List) {
      return [
        for (final p in body['playlists'] as List)
          if (p is Map<String, dynamic>)
            PlaylistInfo(
              id: p['playlistId'] as String? ?? '',
              title: p['title'] as String? ?? '',
              author: p['author'] as String? ?? '',
              videoCount: _num(p['videoCount']) ?? 0,
            ),
      ];
    }
    return const [];
  }

  @override
  Future<List<VideoInfo>> channelSearch(String channelId, String query) async {
    final q = query.toLowerCase();
    return [
      for (final v in await channelVideos(channelId))
        if (v.title.toLowerCase().contains(q)) v,
    ];
  }

  @override
  Future<ChannelInfo> channel(String channelId) async {
    final body = await _get('/api/v1/channels/$channelId');
    if (body is! Map<String, dynamic>) {
      throw InvidiousException('no channel $channelId');
    }
    return ChannelInfo(
      id: channelId,
      name: body['author'] as String? ?? '',
      thumbnailUrl:
          body['authorThumbnails'] is List &&
              (body['authorThumbnails'] as List).isNotEmpty
          ? body['authorThumbnails'].last['url'] as String?
          : null,
      subscribers: _num(body['subCount']),
    );
  }

  @override
  Future<ChannelAbout> channelAbout(String channelId) async {
    final body = await _get('/api/v1/channels/$channelId');
    if (body is! Map<String, dynamic>) return const ChannelAbout();
    return ChannelAbout(
      description: body['description'] as String? ?? '',
      joinedText: body['joined'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (body['joined'] as num).toInt() * 1000,
            ).toIso8601String().split('T').first
          : '',
      videoCountText: '${_num(body['totalViews']) ?? 0} views',
      subscriberCountText: '${_num(body['subCount']) ?? 0} subscribers',
    );
  }

  @override
  Future<PlaylistInfo> playlist(
    String playlistId, {
    String? continuation,
  }) async {
    var page = 1;
    if (continuation != null) {
      page = int.tryParse(continuation) ?? 1;
    }
    final body = await _get('/api/v1/playlists/$playlistId', {'page': '$page'});
    if (body is! Map<String, dynamic>) {
      throw InvidiousException('no playlist $playlistId');
    }
    final videos = _videos(body['videos']);
    final total = _num(body['videoCount']) ?? videos.length;
    return PlaylistInfo(
      id: playlistId,
      title: body['title'] as String? ?? '',
      author: body['author'] as String? ?? '',
      thumbnailUrl: _thumbOf(body),
      videoCount: total,
      videos: videos,
      continuation: videos.length + (page - 1) * 50 < total
          ? '${page + 1}'
          : null,
    );
  }

  @override
  Future<String?> resolveChannel(String url) async {
    final route = parseYouTubeLink(url);
    if (route?.channelId != null) return route!.channelId;
    return null;
  }

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) async =>
      _videos(await _get('/api/v1/channels/$channelId/videos'));

  @override
  Future<List<CaptionCue>> captions(CaptionTrack track) async {
    final response = await _client.get(Uri.parse(track.url));
    if (response.statusCode != 200) {
      throw InvidiousException('captions failed: ${response.statusCode}');
    }
    return parseCaptions(response.body);
  }
}

class InvidiousException implements Exception {
  final String message;
  const InvidiousException(this.message);

  @override
  String toString() => 'InvidiousException: $message';
}
