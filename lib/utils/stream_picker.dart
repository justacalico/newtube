import '../models/video_info.dart';
import 'debug_log.dart';

class StreamChoice {
  final PlayableStream stream;
  final PlayableStream? audio;

  const StreamChoice(this.stream, this.audio);

  String? get audioUrl => audio?.url;
}

final _digitsPattern = RegExp(r'\d+');

int streamPixels(PlayableStream stream) {
  final match = _digitsPattern.firstMatch(stream.quality);
  return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
}

bool sameContainer(PlayableStream a, PlayableStream b) =>
    a.container == null || b.container == null || a.container == b.container;

PlayableStream? bestAudio(List<PlayableStream> streams, {String? container}) {
  var audio = streams.where((s) => !s.hasVideo && s.hasAudio).toList();
  if (container != null) {
    final matching = audio.where((s) => s.container == container).toList();
    if (matching.isNotEmpty) audio = matching;
  }
  final defaults = audio.where((s) => s.isDefaultAudio).toList();
  PlayableStream? best;
  for (final s in defaults.isNotEmpty ? defaults : audio) {
    if (best == null || streamPixels(s) > streamPixels(best)) best = s;
  }
  return best;
}

String? streamCodec(PlayableStream s) {
  final mime = s.mimeType?.toLowerCase() ?? '';
  if (mime.contains('av01') || mime.contains('av1')) return 'av1';
  if (mime.contains('vp9') || mime.contains('vp09')) return 'vp9';
  if (mime.contains('avc') || mime.contains('h264')) return 'avc';
  return null;
}

StreamChoice? pickDefaultStream(
  List<PlayableStream> streams, {
  required bool desktop,
  int preferredQuality = 0,
  int preferredCodec = 0,
}) {
  const codecOrder = [null, 'avc', 'vp9', 'av1'];
  final wantedCodec = preferredCodec >= 0 && preferredCodec < codecOrder.length
      ? codecOrder[preferredCodec]
      : null;
  var videoStreams = streams.where((s) => s.hasVideo).toList();
  if (wantedCodec != null) {
    final matching = videoStreams
        .where((s) => streamCodec(s) == wantedCodec)
        .toList();
    if (matching.isNotEmpty) videoStreams = matching;
  }
  videoStreams.sort((a, b) {
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

  if (preferredQuality < 0) {
    final lowest = videoStreams.last;
    final audio = lowest.hasAudio
        ? null
        : bestAudio(streams, container: lowest.container);
    return StreamChoice(lowest, audio);
  }
  if (preferredQuality > 0) {
    final within = videoStreams
        .where((s) => streamPixels(s) <= preferredQuality)
        .toList();
    if (within.isNotEmpty) {
      final target = within.firstWhere(
        (s) => desktop ? !s.hasAudio : s.hasAudio,
        orElse: () => within.first,
      );
      return StreamChoice(
        target,
        target.hasAudio
            ? null
            : bestAudio(streams, container: target.container),
      );
    }
  }

  if (desktop) {
    final separate = videoStreams.firstWhere(
      (s) => !s.hasAudio,
      orElse: () => videoStreams.first,
    );
    if (!separate.hasAudio) {
      final audio = bestAudio(streams, container: separate.container);
      if (audio != null) return StreamChoice(separate, audio);
    }
  }

  final muxed = videoStreams.firstWhere(
    (s) => s.hasAudio,
    orElse: () => videoStreams.first,
  );
  return StreamChoice(
    muxed,
    muxed.hasAudio ? null : bestAudio(streams, container: muxed.container),
  );
}

StreamChoice pairWithAudio(
  PlayableStream stream,
  List<PlayableStream> all, {
  PlayableStream? audio,
}) {
  if (stream.hasAudio) return StreamChoice(stream, null);
  final track = audio != null && sameContainer(stream, audio)
      ? audio
      : bestAudio(all, container: stream.container) ?? audio;
  return StreamChoice(stream, track);
}
