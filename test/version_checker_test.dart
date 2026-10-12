import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/services/version_checker.dart';

MockClient _respond(List<String> bodies, {int status = 200}) {
  var i = 0;
  return MockClient((request) async {
    final body = bodies[i.clamp(0, bodies.length - 1)];
    i++;
    return http.Response(body, status);
  });
}

void main() {
  test('returns update when newer release exists', () async {
    final checker = VersionChecker(
      client: _respond(['[{"tag_name":"v0.9.0"},{"tag_name":"v1.4.0"}]']),
    );
    final update = await checker.check('1.0.0');
    expect(update.updateAvailable, isTrue);
    expect(update.latestVersion, '1.4.0');
    expect(update.releaseUrl, endsWith('/releases/v1.4.0'));
  });

  test('reports up to date when no newer release', () async {
    final checker = VersionChecker(
      client: _respond(['[{"tag_name":"v1.0.0"}]']),
    );
    final update = await checker.check('2.0.0');
    expect(update.updateAvailable, isFalse);
  });

  test('empty release list yields no update', () async {
    final checker = VersionChecker(client: _respond(['[]']));
    final update = await checker.check('1.0.0');
    expect(update.updateAvailable, isFalse);
    expect(update.releaseUrl, VersionChecker.releasesUrl);
  });

  test('unparseable current version treats any release as update', () async {
    final checker = VersionChecker(
      client: _respond(['[{"tag_name":"v1.0.0"}]']),
    );
    final update = await checker.check('dev-build');
    expect(update.updateAvailable, isTrue);
  });

  test('skips malformed releases and non-semver tags', () async {
    final checker = VersionChecker(
      client: _respond([
        '[{"tag_name":"nightly"},{"tag_name":42},"junk",{"tag_name":"v1.1.0"}]',
      ]),
    );
    final update = await checker.check('1.0.0');
    expect(update.latestVersion, '1.1.0');
  });

  test('paginates when a full page is returned', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      final page = request.url.queryParameters['page'];
      if (page == '1') {
        final tags = List.generate(
          100,
          (i) => '{"tag_name":"v0.0.${i + 1}"}',
        ).join(',');
        return http.Response('[$tags]', 200);
      }
      return http.Response('[{"tag_name":"v9.9.9"}]', 200);
    });
    final update = await VersionChecker(client: client).check('1.0.0');
    expect(calls, 2);
    expect(update.latestVersion, '9.9.9');
  });

  test('non-200 response throws', () {
    final checker = VersionChecker(client: _respond([''], status: 500));
    expect(() => checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
  });

  test('non-list JSON throws', () {
    final checker = VersionChecker(client: _respond(['{"a":1}']));
    expect(() => checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
  });

  test('network error throws VersionCheckException', () {
    final checker = VersionChecker(
      client: MockClient((_) async => throw http.ClientException('down')),
    );
    expect(() => checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
  });

  test('close releases its own client but not injected ones', () {
    final owned = VersionChecker()..close();
    expect(() => owned.close(), returnsNormally);

    final client = _respond(['[]']);
    VersionChecker(client: client).close();
  });
}
