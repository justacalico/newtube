// coverage:ignore-file
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../models/video_info.dart';
import '../utils/debug_log.dart';
import 'innertube_api.dart';
import 'proxy_client.dart';
import 'youtube_api.dart';

class YouTubeExplodeApi implements YouTubeApi {
  final yt.YoutubeExplode _yt;
  final http.Client _http;
  final InnertubeApi _innertube;
  final String? Function()? _proxyPrefix;

  YouTubeExplodeApi({
    yt.YoutubeExplode? explode,
    http.Client? httpClient,
    String? Function()? proxyPrefix,
  }) : _proxyPrefix = proxyPrefix,
       _http = ProxiedClient(
         httpClient ?? http.Client(),
         () => proxyPrefix?.call(),
       ),
       _innertube = InnertubeApi(
         httpClient: httpClient,
         proxyPrefix: proxyPrefix,
       ),
       _yt =
           explode ??
           yt.YoutubeExplode(
             httpClient: yt.YoutubeHttpClient(
               ProxiedClient(http.Client(), () => proxyPrefix?.call()),
             ),
           );

  String _proxied(String url) => proxiedUrl(url, _proxyPrefix?.call());

  @override
  Future<List<VideoInfo>> homeFeed() async {
    try {
      final feed = await _innertubeBrowse('FEwhat_to_watch');
      if (feed.isNotEmpty) return feed;
    } catch (_) {}
    return _mapSearch(await _yt.search.search('popular videos'));
  }

  Future<List<VideoInfo>> _innertubeBrowse(String browseId) async {
    final response = await _http.post(
      Uri.parse(
        'https://www.youtube.com/youtubei/v1/browse'
        '?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'context': {
          'client': {
            'clientName': 'WEB',
            'clientVersion': '2.20250814.01.00',
            'hl': 'en',
            'gl': 'US',
          },
        },
        'browseId': browseId,
      }),
    );
    if (response.statusCode != 200) return const [];
    final videos = <VideoInfo>[];
    _collectVideos(jsonDecode(response.body), videos);
    return videos;
  }

  void _collectVideos(dynamic node, List<VideoInfo> out) {
    if (node is Map<String, dynamic>) {
      final renderer = node['videoRenderer'];
      if (renderer is Map<String, dynamic>) {
        final video = _parseVideoRenderer(renderer);
        if (video != null) out.add(video);
      }
      for (final value in node.values) {
        _collectVideos(value, out);
      }
    } else if (node is List) {
      for (final item in node) {
        _collectVideos(item, out);
      }
    }
  }

  VideoInfo? _parseVideoRenderer(Map<String, dynamic> r) {
    final id = r['videoId'];
    if (id is! String) return null;
    return VideoInfo(
      id: id,
      title: _runs(r['title']) ?? '',
      author: _runs(r['ownerText']) ?? _runs(r['shortBylineText']) ?? '',
      channelId:
          _browseId(r['ownerText']) ?? _browseId(r['shortBylineText']) ?? '',
      thumbnailUrl: _thumbnail(r['thumbnail']),
      duration: _duration(r['lengthText']),
      viewCount: _viewCount(r['viewCountText']),
      uploaded: _runs(r['publishedTimeText']),
    );
  }

  static String? _runs(dynamic node) {
    if (node is! Map<String, dynamic>) return null;
    final simple = node['simpleText'];
    if (simple is String) return simple;
    final runs = node['runs'];
    if (runs is List) {
      return runs
          .whereType<Map<String, dynamic>>()
          .map((r) => r['text'])
          .whereType<String>()
          .join();
    }
    return null;
  }

  static String? _browseId(dynamic node) {
    if (node is! Map<String, dynamic>) return null;
    final runs = node['runs'];
    if (runs is! List || runs.isEmpty) return null;
    final first = runs.first;
    if (first is! Map<String, dynamic>) return null;
    final endpoint = first['navigationEndpoint'];
    if (endpoint is! Map<String, dynamic>) return null;
    final browse = endpoint['browseEndpoint'];
    if (browse is! Map<String, dynamic>) return null;
    final id = browse['browseId'];
    return id is String ? id : null;
  }

  static String? _thumbnail(dynamic node) {
    if (node is! Map<String, dynamic>) return null;
    final thumbs = node['thumbnails'];
    if (thumbs is! List || thumbs.isEmpty) return null;
    final last = thumbs.last;
    if (last is! Map<String, dynamic>) return null;
    final url = last['url'];
    return url is String ? url : null;
  }

  static Duration? _duration(dynamic node) {
    final text = _runs(node);
    if (text == null) return null;
    final parts = text.split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null)) return null;
    final nums = parts.cast<int>();
    var seconds = 0;
    for (final n in nums) {
      seconds = seconds * 60 + n;
    }
    return Duration(seconds: seconds);
  }

  static int _viewCount(dynamic node) {
    final text = _runs(node) ?? '';
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  VideoInfo _mapVideo(yt.Video v) => VideoInfo(
    id: v.id.value,
    title: v.title,
    author: v.author,
    channelId: v.channelId.value,
    thumbnailUrl: v.thumbnails.highResUrl.isEmpty
        ? null
        : _proxied(v.thumbnails.highResUrl),
    duration: v.duration,
    viewCount: v.engagement.viewCount,
    uploaded: v.uploadDateRaw,
  );

  List<VideoInfo> _mapSearch(Iterable<yt.Video> results) =>
      results.map(_mapVideo).toList();

  static Duration? _parseDurationText(String text) {
    final parts = text.split(':').map(int.tryParse).toList();
    if (parts.isEmpty || parts.any((p) => p == null)) return null;
    var seconds = 0;
    for (final n in parts) {
      seconds = seconds * 60 + n!;
    }
    return Duration(seconds: seconds);
  }

  @override
  Future<SearchResults> search(String query) async {
    final results = await _yt.search.searchContent(query);
    final videos = <VideoInfo>[];
    final channels = <ChannelInfo>[];
    for (final r in results) {
      if (r is yt.SearchVideo) {
        videos.add(
          VideoInfo(
            id: r.id.value,
            title: r.title,
            author: r.author,
            channelId: r.channelId,
            thumbnailUrl: r.thumbnails.isEmpty
                ? null
                : r.thumbnails.last.url.toString(),
            duration: _parseDurationText(r.duration),
            viewCount: r.viewCount,
            uploaded: r.uploadDate,
          ),
        );
      } else if (r is yt.SearchChannel) {
        channels.add(
          ChannelInfo(
            id: r.id.value,
            name: r.name,
            thumbnailUrl: r.thumbnails.isEmpty
                ? null
                : r.thumbnails.last.url.toString(),
          ),
        );
      }
    }
    return SearchResults(videos: videos, channels: channels);
  }

  @override
  Future<VideoDetails> videoDetails(String videoId) async {
    final video = await _yt.videos.get(yt.VideoId(videoId));
    final manifest = await _yt.videos.streams.getManifest(videoId);
    final streams = <PlayableStream>[
      for (final s in manifest.videoOnly)
        PlayableStream(
          url: s.url.toString(),
          quality: s.qualityLabel,
          hasAudio: false,
        ),
      for (final s in manifest.muxed)
        PlayableStream(
          url: _proxied(s.url.toString()),
          quality: s.qualityLabel,
        ),
      for (final s in manifest.audioOnly)
        PlayableStream(
          url: _proxied(s.url.toString()),
          quality: 'audio ${s.bitrate.bitsPerSecond ~/ 1000}kbps',
          hasVideo: false,
        ),
      for (final s in manifest.hls)
        PlayableStream(
          url: _proxied(s.url.toString()),
          quality: s.qualityLabel,
        ),
    ];
    debugLog('[api] $videoId: ${streams.length} playable streams');
    return VideoDetails(
      info: VideoInfo(
        id: video.id.value,
        title: video.title,
        author: video.author,
        channelId: video.channelId.value,
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration,
        viewCount: video.engagement.viewCount,
        uploaded: video.uploadDateRaw,
      ),
      description: video.description,
      streams: streams,
    );
  }

  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) async {
    final video = await _yt.videos.get(yt.VideoId(videoId));
    final related = await _yt.videos.getRelatedVideos(video);
    if (related == null) return const [];
    return [
      for (final v in related)
        VideoInfo(
          id: v.id.value,
          title: v.title,
          author: v.author,
          channelId: v.channelId.value,
          thumbnailUrl: v.thumbnails.highResUrl,
          duration: v.duration,
          viewCount: v.engagement.viewCount,
          uploaded: v.uploadDateRaw,
        ),
    ];
  }

  @override
  Future<ChannelInfo> channel(String channelId) async {
    final c = await _yt.channels.get(yt.ChannelId(channelId));
    return ChannelInfo(
      id: c.id.value,
      name: c.title,
      thumbnailUrl: c.logoUrl,
      subscribers: c.subscribersCount,
    );
  }

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) =>
      _innertube.channelVideos(channelId);
}
