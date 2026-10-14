import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/services/innertube_api.dart';

void main() {
  test('playability error throws with reason', () async {
    final api = InnertubeApi(
      httpClient: MockClient(
        (req) async => http.Response(
          '{"playabilityStatus":{"status":"UNPLAYABLE","reason":"Video unavailable"}}',
          200,
        ),
      ),
    );
    expect(
      () => api.videoDetails('x'),
      throwsA(
        isA<PlayabilityException>()
            .having((e) => e.reason, 'reason', 'Video unavailable')
            .having((e) => e.isUnavailable, 'unavail', isTrue),
      ),
    );
  });

  test('age-gated retries via VISIONOS', () async {
    final bodies = <String>[];
    final api = InnertubeApi(
      httpClient: MockClient((req) async {
        bodies.add(req.url.toString());
        if (bodies.length == 1) {
          return http.Response(
            '{"playabilityStatus":{"status":"LOGIN_REQUIRED","reason":"Sign in to confirm your age"}}',
            200,
          );
        }
        return http.Response(
          '{"playabilityStatus":{"status":"OK"},"videoDetails":{"title":"t","author":"a","channelId":"c","lengthSeconds":"60"},"streamingData":{"formats":[]}}',
          200,
        );
      }),
    );
    final details = await api.videoDetails('x');
    expect(details.info.title, 't');
    expect(bodies.length, 2);
  });
}
