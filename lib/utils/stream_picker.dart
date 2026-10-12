import '../models/video_info.dart';
import 'debug_log.dart';

class StreamChoice {
  final PlayableStream stream;
  final String? audioUrl;

  const StreamChoice(this.stream, this.audioUrl);
}

int streamPixels(PlayableStream stream) {
  final match = RegExp(r'\d+').firstMatch(stream.quality);
  return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
}

String? bestAudioUrl(List<PlayableStream> streams) {
  String? url;
  var best = -1;
  for (final s in streams) {
    if (!s.hasVideo && s.hasAudio && streamPixels(s) > best) {
      best = streamPixels(s);
      url = s.url;
    }
  }
  return url;
}

StreamChoice? pickDefaultStream(
  List<PlayableStream> streams, {
  required bool desktop,
}) {
  final videoStreams = streams.where((s) => s.hasVideo).toList()
    ..sort((a, b) {
      final byRes = streamPixels(b).compareTo(streamPixels(a));
      if (byRes != 0) return byRes;
      return (b.hasAudio ? 1 : 0).compareTo(a.hasAudio ? 1 : 0);
    });
  if (videoStreams.isEmpty) {
    final audio = bestAudioUrl(streams);
    if (audio == null) {
      debugLog('[streams] no playable stream');
      return null;
    }
    return StreamChoice(streams.firstWhere((s) => s.url == audio), null);
  }

  if (desktop) {
    final separate = videoStreams.firstWhere(
      (s) => !s.hasAudio,
      orElse: () => videoStreams.first,
    );
    final audio = separate.hasAudio ? null : bestAudioUrl(streams);
    return StreamChoice(separate, audio);
  }

  final muxed = videoStreams.firstWhere(
    (s) => s.hasAudio,
    orElse: () => videoStreams.first,
  );
  return StreamChoice(muxed, muxed.hasAudio ? null : bestAudioUrl(streams));
}

StreamChoice pairWithAudio(PlayableStream stream, List<PlayableStream> all) =>
    StreamChoice(stream, stream.hasAudio ? null : bestAudioUrl(all));
