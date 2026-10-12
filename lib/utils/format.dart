import 'package:intl/intl.dart';

final _compact = NumberFormat.compact();

String formatViewCount(int views) => _compact.format(views);

String formatDuration(Duration? duration) {
  if (duration == null) return '';
  final h = duration.inHours;
  final m = duration.inMinutes.remainder(60);
  final s = duration.inSeconds.remainder(60);
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
}
