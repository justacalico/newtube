import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/utils/chapters.dart';

void main() {
  test('parses timestamp lines from a description', () {
    final chapters = parseChapters(
      'Some intro text\n'
      '0:00 Intro\n'
      '1:23 - Middle part\n'
      '(01:02:03) Long section\n'
      'Buy my merch: shop.example\n',
    );
    expect(chapters, hasLength(3));
    expect(chapters[0].title, 'Intro');
    expect(chapters[1].start, const Duration(minutes: 1, seconds: 23));
    expect(chapters[1].title, 'Middle part');
    expect(chapters[2].start, const Duration(hours: 1, minutes: 2, seconds: 3));
    expect(chapters[2].title, 'Long section');
  });

  test('rejects descriptions without a zero chapter', () {
    expect(parseChapters('1:00 First\n2:00 Second'), isEmpty);
  });

  test('rejects a single timestamp', () {
    expect(parseChapters('0:00 Only one'), isEmpty);
  });

  test('rejects out-of-order timestamps', () {
    expect(parseChapters('0:00 First\n3:00 Later\n2:00 Out of order'), isEmpty);
  });

  test('handles empty and chapterless descriptions', () {
    expect(parseChapters(''), isEmpty);
    expect(parseChapters('just some words'), isEmpty);
  });

  test('chapterAt finds the chapter containing the position', () {
    const chapters = [
      VideoChapter(start: Duration.zero, title: 'Intro'),
      VideoChapter(start: Duration(minutes: 1), title: 'Body'),
    ];
    expect(chapterAt(chapters, Duration.zero)?.title, 'Intro');
    expect(chapterAt(chapters, const Duration(seconds: 59))?.title, 'Intro');
    expect(chapterAt(chapters, const Duration(minutes: 1))?.title, 'Body');
    expect(chapterAt(chapters, const Duration(minutes: 5))?.title, 'Body');
    expect(chapterAt(const [], Duration.zero), isNull);
  });
}
