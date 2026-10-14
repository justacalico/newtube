import 'package:xml/xml.dart';

import '../models/video_info.dart';

List<CaptionCue> parseCaptions(String body) {
  if (body.trimLeft().startsWith('<')) return _parseXml(body);
  return _parseVtt(body);
}

CaptionCue? captionCueAt(List<CaptionCue> cues, Duration position) {
  for (final cue in cues) {
    if (position >= cue.start && position < cue.end) return cue;
  }
  return null;
}

List<CaptionCue> _parseVtt(String body) {
  final cues = <CaptionCue>[];
  final lines = body
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  var i = 0;
  while (i < lines.length) {
    final arrow = lines[i].indexOf('-->');
    if (arrow < 0) {
      i++;
      continue;
    }
    final start = _vttTime(lines[i].substring(0, arrow).trim());
    final timing = lines[i].substring(arrow + 3).trim();
    final end = _vttTime(timing.split(RegExp(r'\s+')).first);
    i++;
    final text = <String>[];
    while (i < lines.length && lines[i].trim().isNotEmpty) {
      text.add(_stripTags(lines[i]));
      i++;
    }
    final joined = text.join('\n').trim();
    if (start != null && end != null && end > start && joined.isNotEmpty) {
      cues.add(CaptionCue(start: start, end: end, text: joined));
    }
  }
  return cues;
}

Duration? _vttTime(String s) {
  final parts = s.split(':');
  if (parts.length < 2 || parts.length > 3) return null;
  final seconds = double.tryParse(parts.last);
  if (seconds == null) return null;
  var minutes = int.tryParse(parts[parts.length - 2]);
  final hours = parts.length == 3 ? int.tryParse(parts[0]) : 0;
  if (minutes == null || hours == null) return null;
  return Duration(
    milliseconds: (hours * 3600000 + minutes * 60000 + seconds * 1000).round(),
  );
}

String _stripTags(String line) {
  return line
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');
}

List<CaptionCue> _parseXml(String body) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(body);
  } on XmlParserException {
    return const [];
  }
  final cues = <CaptionCue>[];
  for (final p in doc.findAllElements('p')) {
    final start = int.tryParse(p.getAttribute('t') ?? '');
    if (start == null) continue;
    final dur = int.tryParse(p.getAttribute('d') ?? '');
    final text = p.innerText.trim();
    if (text.isEmpty) continue;
    cues.add(
      CaptionCue(
        start: Duration(milliseconds: start),
        end: Duration(milliseconds: start + (dur ?? 2000)),
        text: text,
      ),
    );
  }
  return cues;
}
