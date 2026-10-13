import '../models/video_info.dart';
import 'debug_log.dart';

class StreamChoice {
  final PlayableStream stream;
  final PlayableStream? audio;

  const StreamChoice(this.stream, this.audio);

  String? get audioUrl => audio?.url;
}

int streamPixels(PlayableStream stream) {
  final match = RegExp(r'\d+').firstMatch(stream.quality);
  return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
}

PlayableStream? bestAudio(List<PlayableStream> streams) {
  final audio = streams.where((s) => !s.hasVideo && s.hasAudio).toList();
  final defaults = audio.where((s) => s.isDefaultAudio).toList();
  PlayableStream? best;
  for (final s in defaults.isNotEmpty ? defaults : audio) {
    if (best == null || streamPixels(s) > streamPixels(best)) best = s;
  }
  return best;
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
    final audio = bestAudio(streams);
    if (audio == null) {
      debugLog('[streams] no playable stream');
      return null;
    }
    return StreamChoice(audio, null);
  }

  if (desktop) {
    final audio = bestAudio(streams);
    if (audio != null) {
      final separate = videoStreams.firstWhere(
        (s) => !s.hasAudio,
        orElse: () => videoStreams.first,
      );
      if (!separate.hasAudio) return StreamChoice(separate, audio);
    }
  }

  final muxed = videoStreams.firstWhere(
    (s) => s.hasAudio,
    orElse: () => videoStreams.first,
  );
  return StreamChoice(muxed, muxed.hasAudio ? null : bestAudio(streams));
}

StreamChoice pairWithAudio(
  PlayableStream stream,
  List<PlayableStream> all, {
  PlayableStream? audio,
}) => StreamChoice(stream, stream.hasAudio ? null : (audio ?? bestAudio(all)));
