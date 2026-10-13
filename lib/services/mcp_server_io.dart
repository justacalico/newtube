import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/video_info.dart';
import 'mcp_export.dart';
import 'mcp_server.dart';
import 'youtube_api.dart';

// coverage:ignore-start
McpServer createMcpServer({
  required YouTubeApi api,
  required String version,
  void Function(VideoInfo video)? onPlayVideo,
}) => HttpMcpServer(api: api, version: version, onPlayVideo: onPlayVideo);
// coverage:ignore-end

class _InvalidArgs implements Exception {}

class HttpMcpServer implements McpServer {
  static const defaultPort = 8642;
  static const endpointPath = '/mcp';
  static const protocolVersion = '2025-06-18';
  static const _supportedVersions = {'2025-03-26', '2025-06-18'};

  final YouTubeApi api;
  final String version;
  final void Function(VideoInfo video)? onPlayVideo;
  final int port;

  HttpServer? _server;
  Future<void>? _starting;

  HttpMcpServer({
    required this.api,
    required this.version,
    this.onPlayVideo,
    this.port = defaultPort,
  });

  @override
  bool get running => _server != null;

  @override
  String? get url {
    final server = _server;
    if (server == null) return null;
    return 'http://127.0.0.1:${server.port}$endpointPath';
  }

  @override
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    try {
      if (_server != null) return;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      server.listen(_handle);
      _server = server;
    } finally {
      _starting = null;
    }
  }

  @override
  Future<void> stop() async {
    final starting = _starting;
    if (starting != null) {
      try {
        await starting;
      } catch (_) {}
    }
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    if (!_originAllowed(request)) {
      return _respond(request, HttpStatus.forbidden);
    }
    if (request.method == 'GET' && request.uri.path == '/') {
      return _respondJson(request, HttpStatus.ok, _export());
    }
    if (request.uri.path != endpointPath) {
      return _respond(request, HttpStatus.notFound);
    }
    if (request.method != 'POST') {
      return _respond(request, HttpStatus.methodNotAllowed);
    }
    await _handlePost(request);
  }

  Map<String, Object?> _export() =>
      mcspExport(name: 'newtube', version: version, url: url ?? '');

  bool _originAllowed(HttpRequest request) {
    final origin = request.headers.value('origin');
    if (origin == null) return true;
    final host = Uri.tryParse(origin)?.host;
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  Future<void> _handlePost(HttpRequest request) async {
    final Object? message;
    try {
      final body = await utf8.decoder.bind(request).join();
      message = jsonDecode(body);
    } catch (_) {
      return _respondJson(
        request,
        HttpStatus.badRequest,
        _error(null, -32700, 'Parse error'),
      );
    }
    final batch = message is List;
    final responses = <Object?>[];
    for (final m in message is List ? message : [message]) {
      final response = await _dispatch(m);
      if (response != null) responses.add(response);
    }
    if (responses.isEmpty) {
      return _respond(request, HttpStatus.accepted);
    }
    _respondJson(
      request,
      HttpStatus.ok,
      batch ? responses : responses.single,
    );
  }

  Future<Map<String, Object?>?> _dispatch(Object? message) async {
    if (message is! Map) {
      return _error(null, -32600, 'Invalid request');
    }
    final id = message['id'];
    if (id == null) return null;
    switch (message['method']) {
      case 'initialize':
        return _result(id, _initialize(message['params']));
      case 'ping':
        return _result(id, const {});
      case 'tools/list':
        return _result(id, {'tools': mcpToolDefinitions});
      case 'tools/call':
        return _callTool(id, message['params']);
      default:
        return _error(id, -32601, 'Method not found');
    }
  }

  Map<String, Object?> _initialize(Object? params) {
    var negotiated = protocolVersion;
    final requested = params is Map ? params['protocolVersion'] : null;
    if (_supportedVersions.contains(requested)) {
      negotiated = requested as String;
    }
    return {
      'protocolVersion': negotiated,
      'capabilities': {
        'tools': {'listChanged': false},
      },
      'serverInfo': {'name': 'newtube', 'version': version},
    };
  }

  Future<Map<String, Object?>> _callTool(Object? id, Object? params) async {
    final name = params is Map ? params['name'] : null;
    if (name is! String) {
      return _error(id, -32602, 'Invalid params');
    }
    final rawArgs = params is Map ? params['arguments'] : null;
    final arguments = rawArgs is Map ? rawArgs : const {};
    try {
      final data = await switch (name) {
        'search' => _search(arguments),
        'home_feed' => _homeFeed(),
        'video_details' => _videoDetails(arguments),
        'related_videos' => _relatedVideos(arguments),
        'channel_info' => _channelInfo(arguments),
        'channel_videos' => _channelVideos(arguments),
        'play_video' => _playVideo(arguments),
        _ => throw _InvalidArgs(),
      };
      return _result(id, {
        'content': [
          {'type': 'text', 'text': jsonEncode(data)},
        ],
        'structuredContent': data,
      });
    } on _InvalidArgs {
      return _error(id, -32602, 'Invalid params');
    } catch (e) {
      return _result(id, {
        'isError': true,
        'content': [
          {'type': 'text', 'text': '$e'},
        ],
      });
    }
  }

  String _arg(Map<dynamic, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value is String && value.isNotEmpty) return value;
    throw _InvalidArgs();
  }

  Future<Object> _search(Map<dynamic, dynamic> args) async {
    final results = await api.search(_arg(args, 'query'));
    return {
      'videos': [for (final v in results.videos) _videoJson(v)],
      'channels': [for (final c in results.channels) _channelJson(c)],
    };
  }

  Future<Object> _homeFeed() async => {
    'videos': [for (final v in await api.homeFeed()) _videoJson(v)],
  };

  Future<Object> _videoDetails(Map<dynamic, dynamic> args) async {
    final details = await api.videoDetails(_arg(args, 'video_id'));
    return {
      'video': _videoJson(details.info),
      'description': details.description,
      'streams': [
        for (final s in details.streams)
          {
            'url': s.url,
            'quality': s.quality,
            'hasVideo': s.hasVideo,
            'hasAudio': s.hasAudio,
          },
      ],
    };
  }

  Future<Object> _relatedVideos(Map<dynamic, dynamic> args) async => {
    'videos': [
      for (final v in await api.relatedVideos(_arg(args, 'video_id')))
        _videoJson(v),
    ],
  };

  Future<Object> _channelInfo(Map<dynamic, dynamic> args) async => {
    'channel': _channelJson(await api.channel(_arg(args, 'channel_id'))),
  };

  Future<Object> _channelVideos(Map<dynamic, dynamic> args) async => {
    'videos': [
      for (final v in await api.channelVideos(_arg(args, 'channel_id')))
        _videoJson(v),
    ],
  };

  Future<Object> _playVideo(Map<dynamic, dynamic> args) async {
    final videoId = _arg(args, 'video_id');
    final onPlay = onPlayVideo;
    if (onPlay == null) throw StateError('playback is not available');
    final details = await api.videoDetails(videoId);
    onPlay(details.info);
    return {'playing': _videoJson(details.info)};
  }

  Map<String, Object?> _videoJson(VideoInfo v) => {
    'id': v.id,
    'title': v.title,
    'author': v.author,
    'channelId': v.channelId,
    if (v.thumbnailUrl != null) 'thumbnailUrl': v.thumbnailUrl,
    if (v.duration != null) 'durationSeconds': v.duration!.inSeconds,
    'viewCount': v.viewCount,
    if (v.uploaded != null) 'uploaded': v.uploaded,
  };

  Map<String, Object?> _channelJson(ChannelInfo c) => {
    'id': c.id,
    'name': c.name,
    if (c.thumbnailUrl != null) 'thumbnailUrl': c.thumbnailUrl,
    if (c.subscribers != null) 'subscribers': c.subscribers,
  };

  Map<String, Object?> _result(Object? id, Object? result) => {
    'jsonrpc': '2.0',
    'id': id,
    'result': result,
  };

  Map<String, Object?> _error(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };

  void _respond(HttpRequest request, int status) {
    request.response
      ..statusCode = status
      ..contentLength = 0;
    request.response.close();
  }

  void _respondJson(HttpRequest request, int status, Object? body) {
    final bytes = utf8.encode(jsonEncode(body));
    request.response
      ..statusCode = status
      ..contentLength = bytes.length
      ..headers.contentType = ContentType.json
      ..add(bytes);
    request.response.close();
  }
}
