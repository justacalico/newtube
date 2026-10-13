import '../models/video_info.dart';

final _timestampLine = RegExp(
  r'^\s*[\(\[]?(\d{1,3}):(\d{2})(?::(\d{2}))?[\)\]]?\s*[-–—:]?\s*(.+?)\s*$',
);

/// Pulls YouTube-style chapters out of a video description. A video only
/// counts as chaptered when there are at least two timestamp lines in
/// ascending order and the first one starts at zero, matching YouTube's own
/// rules for chapter markers.
List<VideoChapter> parseChapters(String description) {
  final chapters = <VideoChapter>[];
  for (final line in description.split('\n')) {
    final match = _timestampLine.firstMatch(line);
    if (match == null) continue;
    final a = int.parse(match[1]!);
    final b = int.parse(match[2]!);
    final c = match[3] == null ? 0 : int.parse(match[3]!);
    final start = match[3] == null
        ? Duration(minutes: a, seconds: b)
        : Duration(hours: a, minutes: b, seconds: c);
    chapters.add(VideoChapter(start: start, title: match[4]!));
  }
  if (chapters.length < 2 || chapters.first.start != Duration.zero) {
    return const [];
  }
  for (var i = 1; i < chapters.length; i++) {
    if (chapters[i].start <= chapters[i - 1].start) return const [];
  }
  return chapters;
}

VideoChapter? chapterAt(List<VideoChapter> chapters, Duration position) {
  VideoChapter? current;
  for (final chapter in chapters) {
    if (chapter.start > position) break;
    current = chapter;
  }
  return current;
}
