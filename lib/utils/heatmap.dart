import '../models/video_info.dart';

List<HeatMarker> parseHeatMarkers(Map<String, dynamic>? response) {
  final updates = response?['frameworkUpdates'];
  if (updates is! Map<String, dynamic>) return const [];
  final batch = updates['entityBatchUpdate'];
  if (batch is! Map<String, dynamic>) return const [];
  final mutations = batch['mutations'];
  if (mutations is! List) return const [];
  for (final mutation in mutations) {
    if (mutation is! Map<String, dynamic>) continue;
    final payload = mutation['payload'];
    if (payload is! Map<String, dynamic>) continue;
    final entity = payload['markersEntity'];
    if (entity is! Map<String, dynamic>) continue;
    final markersMap = entity['markersMap'];
    if (markersMap is! List) continue;
    for (final entry in markersMap) {
      if (entry is! Map<String, dynamic>) continue;
      final heatmap = entry['value']?['heatmap'];
      if (heatmap is! Map<String, dynamic>) continue;
      final markers = heatmap['heatMarkers'];
      if (markers is! List) continue;
      final out = <HeatMarker>[];
      for (final m in markers) {
        if (m is! Map<String, dynamic>) continue;
        final millis = int.tryParse('${m['timeRangeStartMillis']}') ?? 0;
        final score = m['heatScoreNormalized'];
        out.add(
          HeatMarker(
            start: Duration(milliseconds: millis),
            intensity: score is num ? score.toDouble() : 0,
          ),
        );
      }
      if (out.isNotEmpty) return out;
    }
  }
  return const [];
}
