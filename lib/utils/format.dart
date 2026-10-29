import 'package:intl/intl.dart';

final _compact = <String, NumberFormat>{};

String formatViewCount(int views, [String? locale]) =>
    (_compact[locale ?? ''] ??= NumberFormat.compact(
      locale: locale,
    )).format(views);

String formatDuration(Duration? duration) {
  if (duration == null) return '';
  final h = duration.inHours;
  final m = duration.inMinutes.remainder(60);
  final s = duration.inSeconds.remainder(60);
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}
