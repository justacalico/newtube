import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/utils/stream_picker.dart';

const v720 = PlayableStream(url: 'u720', quality: '720p', hasAudio: false);
const v360v = PlayableStream(url: 'u360v', quality: '360p', hasAudio: false);
const m360 = PlayableStream(url: 'm360', quality: '360p');
const m180 = PlayableStream(url: 'm180', quality: '180p');
const a128 = PlayableStream(
  url: 'a128',
  quality: 'audio 128kbps',
  hasVideo: false,
);
const a64 = PlayableStream(
  url: 'a64',
  quality: 'audio 64kbps',
  hasVideo: false,
);
const odd = PlayableStream(url: 'odd', quality: 'premium');

void main() {
  test('streamPixels parses leading numbers', () {
    expect(streamPixels(v720), 720);
    expect(streamPixels(a128), 128);
    expect(streamPixels(odd), 0);
  });

  test('bestAudioUrl picks highest bitrate audio', () {
    expect(bestAudioUrl(const [m360, a64, a128]), 'a128');
    expect(bestAudioUrl(const [m360]), isNull);
  });

  test('desktop prefers separate video with paired audio', () {
    final choice = pickDefaultStream(const [
      m360,
      a128,
      v360v,
      v720,
    ], desktop: true)!;
    expect(choice.stream, v720);
    expect(choice.audioUrl, 'a128');
  });

  test('desktop falls back to muxed when no video-only stream', () {
    final choice = pickDefaultStream(const [m180, m360], desktop: true)!;
    expect(choice.stream, m360);
    expect(choice.audioUrl, isNull);
  });

  test('mobile prefers best muxed stream', () {
    final choice = pickDefaultStream(const [
      v720,
      m180,
      a128,
      m360,
    ], desktop: false)!;
    expect(choice.stream, m360);
    expect(choice.audioUrl, isNull);
  });

  test('mobile falls back to video-only with audio pair', () {
    final choice = pickDefaultStream(const [v720, a128], desktop: false)!;
    expect(choice.stream, v720);
    expect(choice.audioUrl, 'a128');
  });

  test('audio-only list still plays', () {
    final choice = pickDefaultStream(const [a128], desktop: true)!;
    expect(choice.stream, a128);
    expect(choice.audioUrl, isNull);
  });

  test('empty stream list returns null', () {
    expect(pickDefaultStream(const [], desktop: true), isNull);
  });

  test('pairWithAudio attaches audio only when needed', () {
    expect(pairWithAudio(v720, const [a128]).audioUrl, 'a128');
    expect(pairWithAudio(m360, const [a128]).audioUrl, isNull);
  });
}
