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
}
