import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/services/innertube_api.dart';

void main() {
  test('videoDetails caches for 5 minutes', () async {
    var calls = 0;
    final api = InnertubeApi(
      httpClient: MockClient((req) async {
        calls++;
        return http.Response(
          '{"playabilityStatus":{"status":"OK"},"videoDetails":{"title":"t","author":"a","channelId":"c","lengthSeconds":"60"},"streamingData":{"formats":[]}}',
          200,
        );
      }),
    );
    final a = await api.videoDetails('v1');
    final b = await api.videoDetails('v1');
    expect(identical(a, b), isTrue);
    final c = await api.videoDetails('v2');
    expect(c, isNotNull);
    expect(calls, 2);
  });

  test('videoDetails dedupes in-flight requests', () async {
    var calls = 0;
    final api = InnertubeApi(
      httpClient: MockClient((req) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(
          '{"playabilityStatus":{"status":"OK"},"videoDetails":{"title":"t","author":"a","channelId":"c","lengthSeconds":"60"},"streamingData":{"formats":[]}}',
          200,
        );
      }),
    );
    final results = await Future.wait([
      api.videoDetails('v1'),
      api.videoDetails('v1'),
    ]);
    expect(calls, 1);
    expect(identical(results[0], results[1]), isTrue);
  });

  test('videoDetails cache evicts the oldest entry past 50', () async {
    var calls = 0;
    final api = InnertubeApi(
      httpClient: MockClient((req) async {
        calls++;
        return http.Response(
          '{"playabilityStatus":{"status":"OK"},"videoDetails":{"title":"t","author":"a","channelId":"c","lengthSeconds":"60"},"streamingData":{"formats":[]}}',
          200,
        );
      }),
    );
    for (var i = 0; i < 51; i++) {
      await api.videoDetails('v$i');
    }
    expect(calls, 51);
    await api.videoDetails('v50');
    expect(calls, 51);
    await api.videoDetails('v0');
    expect(calls, 52);
  });
}
