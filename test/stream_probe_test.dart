import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/utils/stream_probe.dart';

const _a = PlayableStream(url: 'https://v/a', quality: '720p');
const _b = PlayableStream(url: 'https://v/b', quality: '360p');
const _c = PlayableStream(
  url: 'https://v/c',
  quality: 'audio 128kbps',
  hasVideo: false,
);

void main() {
  group('streamPlayable', () {
    for (final status in [200, 206]) {
      test('status $status is playable', () async {
        final client = MockClient.streaming(
          (_, _) async =>
              http.StreamedResponse(const Stream<List<int>>.empty(), status),
        );
        expect(await streamPlayable(client, 'https://v/x'), isTrue);
      });
    }

    test('client errors are not playable', () async {
      final client = MockClient.streaming(
        (_, _) async => throw StateError('down'),
      );
      expect(await streamPlayable(client, 'https://v/x'), isFalse);
    });

    test('sends an open ended range request', () async {
      http.BaseRequest? seen;
      final client = MockClient.streaming((request, _) async {
        seen = request;
        return http.StreamedResponse(const Stream<List<int>>.empty(), 403);
      });
      expect(await streamPlayable(client, 'https://v/x'), isFalse);
      expect(seen!.method, 'GET');
      expect(seen!.headers['range'], 'bytes=0-');
    });
  });

  group('playableStreams', () {
    test('returns the input unchanged when empty', () async {
      final streams = await playableStreams(
        const [],
        MockClient.streaming(
          (_, _) async =>
              http.StreamedResponse(const Stream<List<int>>.empty(), 403),
        ),
      );
      expect(streams, isEmpty);
    });

    test('keeps only playable streams', () async {
      final client = MockClient.streaming((request, _) async {
        final ok = request.url.path != '/b';
        return http.StreamedResponse(
          const Stream<List<int>>.empty(),
          ok ? 206 : 403,
        );
      });
      final streams = await playableStreams(const [_a, _b, _c], client);
      expect(streams.map((s) => s.url), ['https://v/a', 'https://v/c']);
    });

    test('falls back to the full list when every probe fails', () async {
      final client = MockClient.streaming(
        (_, _) async =>
            http.StreamedResponse(const Stream<List<int>>.empty(), 403),
      );
      final streams = await playableStreams(const [_a, _b], client);
      expect(streams.length, 2);
    });
  });
}
