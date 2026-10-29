import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/file_saver_io.dart';
import 'package:newtube/services/mcp_export.dart';
import 'package:newtube/services/mcp_server.dart';
import 'package:newtube/services/mcp_server_io.dart';

import 'fakes.dart';

typedef HttpReply = ({int status, String body});

Future<HttpReply> _request(
  int port, {
  String method = 'POST',
  String path = '/mcp',
  String? body,
  Map<String, String> headers = const {},
}) async {
  final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
  final request = StringBuffer(
    '$method $path HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n',
  );
  if (body != null) {
    request.write(
      'Content-Type: application/json\r\n'
      'Content-Length: ${utf8.encode(body).length}\r\n',
    );
  }
  for (final entry in headers.entries) {
    request.write('${entry.key}: ${entry.value}\r\n');
  }
  request.write('\r\n');
  socket.write(request.toString());
  if (body != null) socket.write(body);
  await socket.flush();
  final raw = await utf8
      .decodeStream(socket)
      .timeout(const Duration(seconds: 10));
  socket.destroy();
  final split = raw.indexOf('\r\n\r\n');
  final status = int.parse(raw.substring(0, split).split(' ')[1]);
  return (status: status, body: raw.substring(split + 4));
}

int _port(HttpMcpServer server) =>
    int.parse(Uri.parse(server.url!).port.toString());

Map<String, Object?> _rpc(String method, [Object? params, Object? id = 1]) => {
  'jsonrpc': '2.0',
  'id': id,
  'method': method,
  'params': ?params,
};

void main() {
  late HttpMcpServer server;
  late FakeYouTubeApi api;
  final played = <VideoInfo>[];

  setUp(() async {
    played.clear();
    api = FakeYouTubeApi(
      feed: testVideos,
      searchResults: const SearchResults(
        videos: testVideos,
        channels: [testChannel],
      ),
      related: testVideos,
      uploads: testVideos,
    );
    server = HttpMcpServer(
      api: api,
      version: '1.2.3',
      port: 0,
      onPlayVideo: played.add,
    );
    await server.start();
  });

  tearDown(() => server.stop());

  Future<Map<String, Object?>> call(
    String method, [
    Object? params,
    Object? id = 1,
  ]) async {
    final reply = await _request(
      _port(server),
      body: jsonEncode(_rpc(method, params, id)),
    );
    expect(reply.status, HttpStatus.ok);
    return jsonDecode(reply.body) as Map<String, Object?>;
  }

  test('start and stop manage the listener', () async {
    await server.stop();
    expect(server.running, isFalse);
    expect(server.url, isNull);

    await server.start();
    expect(server.running, isTrue);
    expect(server.url, 'http://127.0.0.1:${_port(server)}/mcp');

    await server.start();
    expect(server.running, isTrue);
  });

  test('stop waits for an in-flight start', () async {
    await server.stop();
    final starting = server.start();
    final stopping = server.stop();
    await starting;
    await stopping;
    expect(server.running, isFalse);
    expect(server.url, isNull);
  });

  test('initialize returns capabilities and negotiates version', () async {
    final result =
        (await call('initialize', {
              'protocolVersion': '2025-03-26',
              'capabilities': <String, dynamic>{},
              'clientInfo': {'name': 'test', 'version': '0'},
            }))['result']
            as Map<String, Object?>;
    expect(result['protocolVersion'], '2025-03-26');
    expect(result['serverInfo'], {'name': 'newtube', 'version': '1.2.3'});
    expect(result['capabilities'], isA<Map<dynamic, dynamic>>());

    final fallback =
        (await call('initialize', {'protocolVersion': '1999-01-01'}))['result']
            as Map<String, Object?>;
    expect(fallback['protocolVersion'], HttpMcpServer.protocolVersion);

    final noParams =
        (await call('initialize'))['result'] as Map<String, Object?>;
    expect(noParams['protocolVersion'], HttpMcpServer.protocolVersion);
  });

  test('ping returns an empty result', () async {
    expect(await call('ping'), {
      'jsonrpc': '2.0',
      'id': 1,
      'result': <String, Object?>{},
    });
  });

  test('tools/list describes every tool', () async {
    final tools = (await call('tools/list'))['result'] as Map<String, Object?>;
    final names = [for (final t in tools['tools'] as List) (t as Map)['name']];
    expect(names, [
      'search',
      'home_feed',
      'video_details',
      'related_videos',
      'channel_info',
      'channel_videos',
      'play_video',
    ]);
  });

  test('tools/call search returns videos and channels', () async {
    final result = await call('tools/call', {
      'name': 'search',
      'arguments': {'query': 'cats'},
    });
    final data = (result['result'] as Map)['structuredContent'] as Map;
    expect((data['videos'] as List).first['id'], 'v1');
    expect((data['channels'] as List).single['id'], 'c1');
  });

  test('tools/call home_feed, related and channel tools', () async {
    for (final entry in {
      'home_feed': null,
      'related_videos': {'video_id': 'v1'},
      'channel_videos': {'channel_id': 'c1'},
    }.entries) {
      final result = await call('tools/call', {
        'name': entry.key,
        'arguments': entry.value,
      });
      final data = (result['result'] as Map)['structuredContent'] as Map;
      expect((data['videos'] as List).first['id'], 'v1');
    }

    final channel = await call('tools/call', {
      'name': 'channel_info',
      'arguments': {'channel_id': 'c1'},
    });
    final info =
        ((channel['result'] as Map)['structuredContent'] as Map)['channel']
            as Map;
    expect(info['name'], 'Channel One');
    expect(info['subscribers'], 54321);
  });

  test('tools/call video_details includes streams', () async {
    final result = await call('tools/call', {
      'name': 'video_details',
      'arguments': {'video_id': 'v1'},
    });
    final data = (result['result'] as Map)['structuredContent'] as Map;
    expect((data['video'] as Map)['id'], 'v1');
    expect(data['description'], 'A video description');
    expect((data['streams'] as List).length, 3);
  });

  test('tools/call play_video opens the video in the app', () async {
    final result = await call('tools/call', {
      'name': 'play_video',
      'arguments': {'video_id': 'v1'},
    });
    final data = (result['result'] as Map)['structuredContent'] as Map;
    expect((data['playing'] as Map)['id'], 'v1');
    expect(played.single.id, 'v1');
  });

  test('play_video without a handler reports an error', () async {
    final solo = HttpMcpServer(api: api, version: '1', port: 0);
    await solo.start();
    addTearDown(solo.stop);
    final reply = await _request(
      _port(solo),
      body: jsonEncode(
        _rpc('tools/call', {
          'name': 'play_video',
          'arguments': {'video_id': 'v1'},
        }),
      ),
    );
    final result = (jsonDecode(reply.body) as Map)['result'] as Map;
    expect(result['isError'], isTrue);
  });

  test('unknown tool and bad arguments are invalid params', () async {
    for (final params in [
      {'name': 'nope'},
      {'name': 'search', 'arguments': <String, Object?>{}},
      {
        'name': 'video_details',
        'arguments': {'video_id': ''},
      },
      <String, Object?>{},
      'nope',
    ]) {
      final response = await call('tools/call', params);
      expect((response['error'] as Map)['code'], -32602);
    }
  });

  test('tool failure returns an isError result', () async {
    api.error = 'down';
    final result = await call('tools/call', {
      'name': 'search',
      'arguments': {'query': 'x'},
    });
    expect((result['result'] as Map)['isError'], isTrue);
  });

  test('unknown method returns method not found', () async {
    final response = await call('bogus/method');
    expect((response['error'] as Map)['code'], -32601);
  });

  test('notifications get an empty 202 response', () async {
    final reply = await _request(
      _port(server),
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'notifications/initialized',
      }),
    );
    expect(reply.status, HttpStatus.accepted);
    expect(reply.body, isEmpty);
  });

  test('batch requests get a batch response', () async {
    final reply = await _request(
      _port(server),
      body: jsonEncode([
        _rpc('ping'),
        _rpc('tools/list'),
        {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
      ]),
    );
    expect(reply.status, HttpStatus.ok);
    final responses = jsonDecode(reply.body) as List;
    expect(responses.length, 2);
  });

  test('invalid json is a parse error and garbage is invalid', () async {
    final reply = await _request(_port(server), body: '{nope');
    expect(reply.status, HttpStatus.badRequest);
    expect((jsonDecode(reply.body) as Map)['error'], {
      'code': -32700,
      'message': 'Parse error',
    });

    final garbage = await _request(_port(server), body: '42');
    expect((jsonDecode(garbage.body) as Map)['error'], {
      'code': -32600,
      'message': 'Invalid request',
    });
  });

  test('request without a method is invalid', () async {
    final reply = await _request(
      _port(server),
      body: jsonEncode({'jsonrpc': '2.0', 'id': 5}),
    );
    expect((jsonDecode(reply.body) as Map)['error'], {
      'code': -32601,
      'message': 'Method not found',
    });
  });

  test('rejects wrong paths, non-POST methods and foreign origins', () async {
    expect(
      (await _request(_port(server), path: '/nope')).status,
      HttpStatus.notFound,
    );
    expect(
      (await _request(_port(server), method: 'GET', path: '/')).status,
      HttpStatus.notFound,
    );
    expect(
      (await _request(_port(server), method: 'GET')).status,
      HttpStatus.methodNotAllowed,
    );
    expect(
      (await _request(_port(server), method: 'DELETE')).status,
      HttpStatus.methodNotAllowed,
    );
    expect(
      (await _request(
        _port(server),
        headers: {'Origin': 'http://evil.example'},
      )).status,
      HttpStatus.forbidden,
    );
    expect(
      (await _request(
        _port(server),
        headers: {'Origin': 'http://localhost:3000'},
        body: jsonEncode(_rpc('ping')),
      )).status,
      HttpStatus.ok,
    );
  });

  test('mcpbExport produces an installable bundle', () {
    final bundle = ZipDecoder().decodeBytes(
      mcpbExport(
        name: 'newtube',
        version: '0.5.0',
        url: 'http://127.0.0.1:8642/mcp',
      ),
    );
    final manifest = jsonDecode(
      utf8.decode(bundle.findFile('manifest.json')!.readBytes()!),
    ) as Map<String, Object?>;
    expect(manifest['manifest_version'], '0.3');
    expect(manifest['name'], 'newtube');
    expect(manifest['version'], '0.5.0');
    expect(manifest['server'], {
      'type': 'node',
      'entry_point': 'server/bridge.js',
      'mcp_config': {
        'command': 'node',
        'args': [r'${__dirname}/server/bridge.js', 'http://127.0.0.1:8642/mcp'],
      },
    });
    expect((manifest['tools'] as List).length, mcpToolDefinitions.length);
    expect(
      utf8.decode(bundle.findFile('server/bridge.js')!.readBytes()!),
      contains('await fetch(endpoint,'),
    );
  });

  test('writeFile writes the export to a path', () async {
    final dir = await Directory.systemTemp.createTemp('mcpb');
    addTearDown(() => dir.delete(recursive: true));
    final target = '${dir.path}${Platform.pathSeparator}newtube.mcpb';
    final path = await writeFile(target, utf8.encode('bundle'));
    expect(path, target);
    expect(File(path).readAsStringSync(), 'bundle');
  });

  test('default port constant', () {
    expect(HttpMcpServer.defaultPort, 8642);
    expect(HttpMcpServer.endpointPath, '/mcp');
  });

  test('unsupported server is a no-op', () async {
    final unsupported = UnsupportedMcpServer();
    expect(unsupported.running, isFalse);
    expect(unsupported.url, isNull);
    await unsupported.start();
    expect(unsupported.running, isFalse);
    await unsupported.stop();
  });
}
