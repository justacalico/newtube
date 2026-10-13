import 'package:http/http.dart' as http;

import '../models/video_info.dart';
import 'debug_log.dart';

Future<bool> streamPlayable(http.Client client, String url) async {
  try {
    final request = http.Request('GET', Uri.parse(url))
      ..headers['range'] = 'bytes=0-';
    final response = await client.send(request);
    await response.stream.listen((_) {}).cancel();
    return response.statusCode == 200 || response.statusCode == 206;
  } catch (_) {
    return false;
  }
}

Future<List<PlayableStream>> playableStreams(
  List<PlayableStream> streams,
  http.Client client,
) async {
  if (streams.isEmpty) return streams;
  final results = await Future.wait([
    for (final s in streams) streamPlayable(client, s.url),
  ]);
  final playable = [
    for (var i = 0; i < streams.length; i++)
      if (results[i]) streams[i],
  ];
  if (playable.isEmpty) {
    debugLog('[streams] every stream probe failed');
    return streams;
  }
  if (playable.length != streams.length) {
    debugLog(
      '[streams] dropped ${streams.length - playable.length} '
      'unplayable streams',
    );
  }
  return playable;
}
