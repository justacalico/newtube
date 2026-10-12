import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/utils/version_utils.dart';

void main() {
  group('Version.parse', () {
    test('parses plain versions', () {
      final v = Version.parse('1.2.3')!;
      expect(v.core, [1, 2, 3]);
      expect(v.pre, isNull);
      expect(v.toString(), '1.2.3');
    });

    test('strips v prefix and build metadata', () {
      expect(Version.parse('v1.2.3')!.core, [1, 2, 3]);
      expect(Version.parse('V2.0.0+build5')!.core, [2, 0, 0]);
    });

    test('parses prerelease', () {
      final v = Version.parse('1.0.0-alpha.1')!;
      expect(v.pre, ['alpha', '1']);
      expect(v.toString(), '1.0.0-alpha.1');
    });

    test('rejects invalid input', () {
      expect(Version.parse(null), isNull);
      expect(Version.parse(''), isNull);
      expect(Version.parse('1.2'), isNull);
      expect(Version.parse('1.2.3.4'), isNull);
      expect(Version.parse('1.02.3'), isNull);
      expect(Version.parse('a.b.c'), isNull);
      expect(Version.parse('1.2.x'), isNull);
      expect(Version.parse('1.2.3-'), isNull);
      expect(Version.parse('1.2.3-a..b'), isNull);
      expect(Version.parse('1.2.3-é'), isNull);
      expect(Version.parse('1.2.3-01'), isNull);
    });
  });

  group('Version.compareTo', () {
    test('compares core parts', () {
      expect(Version.parse('1.0.0')!.compareTo(Version.parse('2.0.0')!), -1);
      expect(Version.parse('1.2.0')!.compareTo(Version.parse('1.3.0')!), -1);
      expect(Version.parse('1.2.3')!.compareTo(Version.parse('1.2.4')!), -1);
      expect(Version.parse('1.2.3')!.compareTo(Version.parse('1.2.3')!), 0);
    });

    test('release beats prerelease', () {
      expect(Version.parse('1.0.0')!.compareTo(Version.parse('1.0.0-a')!), 1);
      expect(Version.parse('1.0.0-a')!.compareTo(Version.parse('1.0.0')!), -1);
    });

    test('numeric prerelease identifiers compare numerically', () {
      expect(
        Version.parse('1.0.0-2')!.compareTo(Version.parse('1.0.0-10')!),
        -1,
      );
      expect(Version.parse('1.0.0-a')!.compareTo(Version.parse('1.0.0-1')!), 1);
      expect(
        Version.parse('1.0.0-1')!.compareTo(Version.parse('1.0.0-a')!),
        -1,
      );
      expect(
        Version.parse('1.0.0-a')!.compareTo(Version.parse('1.0.0-b')!),
        -1,
      );
      expect(
        Version.parse('1.0.0-a')!.compareTo(Version.parse('1.0.0-a.1')!),
        -1,
      );
      expect(
        Version.parse('1.0.0-a.1')!.compareTo(Version.parse('1.0.0-a')!),
        1,
      );
      expect(Version.parse('1.0.0-a')!.compareTo(Version.parse('1.0.0-a')!), 0);
    });
  });
}
