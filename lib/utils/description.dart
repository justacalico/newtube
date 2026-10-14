import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

final _descriptionToken = RegExp(
  r'(https?://[^\s]+)|(?<![\w:])(\d{1,2}):(\d{2})(?::(\d{2}))?(?![\w:])',
);

List<InlineSpan> descriptionSpans(
  String text, {
  TextStyle? style,
  TextStyle? linkStyle,
  void Function(Uri url)? onLink,
  void Function(Duration time)? onTimestamp,
}) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _descriptionToken.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: style),
      );
    }
    final url = match.group(1);
    if (url != null) {
      final uri = Uri.tryParse(url);
      spans.add(
        TextSpan(
          text: url,
          style: linkStyle,
          recognizer: uri == null || onLink == null
              ? null
              : (TapGestureRecognizer()..onTap = () => onLink(uri)),
        ),
      );
    } else {
      final raw = match.group(0)!;
      final h = match.group(4) != null ? int.parse(match.group(2)!) : 0;
      final m = match.group(4) != null
          ? int.parse(match.group(3)!)
          : int.parse(match.group(2)!);
      final sec = int.parse(match.group(4) ?? match.group(3)!);
      final time = Duration(hours: h, minutes: m, seconds: sec);
      spans.add(
        TextSpan(
          text: raw,
          style: linkStyle,
          recognizer: onTimestamp == null
              ? null
              : (TapGestureRecognizer()..onTap = () => onTimestamp(time)),
        ),
      );
    }
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: style));
  }
  if (spans.isEmpty) spans.add(TextSpan(text: text, style: style));
  return spans;
}
