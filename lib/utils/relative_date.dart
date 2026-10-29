final _agoPattern = RegExp(
  r'(\d+)\s+(second|minute|hour|day|week|month|year)s?\s+ago',
  caseSensitive: false,
);

DateTime? parseRelativeDate(String? text, [DateTime? now]) {
  if (text == null || text.isEmpty) return null;
  final m = _agoPattern.firstMatch(text);
  if (m == null) return null;
  final n = int.parse(m[1]!);
  final unit = m[2]!.toLowerCase();
  final ref = now ?? DateTime.now();
  return switch (unit) {
    'second' => ref.subtract(Duration(seconds: n)),
    'minute' => ref.subtract(Duration(minutes: n)),
    'hour' => ref.subtract(Duration(hours: n)),
    'day' => ref.subtract(Duration(days: n)),
    'week' => ref.subtract(Duration(days: n * 7)),
    'month' => ref.subtract(Duration(days: n * 30)),
    'year' => ref.subtract(Duration(days: n * 365)),
    _ => null,
  };
}
