import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/utils/format.dart';

void main() {
  test('formatViewCount compacts', () {
    expect(formatViewCount(0), '0');
    expect(formatViewCount(999), '999');
    expect(formatViewCount(12345), '12.3K');
    expect(formatViewCount(1500000), '1.5M');
  });

  test('formatViewCount honors the passed locale', () {
    expect(formatViewCount(1500000, 'ru'), isNot(formatViewCount(1500000)));
    expect(formatViewCount(1500000, 'ru'), contains('млн'));
    expect(formatViewCount(12345, 'en_GB'), '12.3k');
  });

  test('formatDuration handles null, minutes and hours', () {
    expect(formatDuration(null), '');
    expect(formatDuration(const Duration(seconds: 5)), '0:05');
    expect(formatDuration(const Duration(minutes: 3, seconds: 21)), '3:21');
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });
}
