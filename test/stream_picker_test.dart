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
const aDub = PlayableStream(
  url: 'aDub',
  quality: 'audio 192kbps',
  hasVideo: false,
  audioLanguage: 'es',
  audioTrackName: 'Español',
  isDefaultAudio: false,
);
const v1080mp4 = PlayableStream(
  url: 'v1080mp4',
  quality: '1080p',
  hasAudio: false,
  container: 'mp4',
);
const aMp4 = PlayableStream(
  url: 'aMp4',
  quality: 'audio 130kbps',
  hasVideo: false,
  container: 'mp4',
);
const aWebm = PlayableStream(
  url: 'aWebm',
  quality: 'audio 136kbps',
  hasVideo: false,
  container: 'webm',
);

void main() {
  test('streamPixels parses leading numbers', () {
    expect(streamPixels(v720), 720);
    expect(streamPixels(a128), 128);
    expect(streamPixels(odd), 0);
  });

  test('bestAudio picks highest bitrate audio', () {
    expect(bestAudio(const [m360, a64, a128]), a128);
    expect(bestAudio(const [m360]), isNull);
  });

  test('bestAudio prefers the default track over louder dubs', () {
    expect(bestAudio(const [aDub, a128]), a128);
    expect(bestAudio(const [aDub]), aDub);
  });

  test('desktop prefers separate video with paired audio', () {
    final choice = pickDefaultStream(const [
      m360,
      a128,
      v360v,
      v720,
    ], desktop: true)!;
    expect(choice.stream, v720);
    expect(choice.audio, a128);
    expect(choice.audioUrl, 'a128');
  });

  test('desktop falls back to muxed when no video-only stream', () {
    final choice = pickDefaultStream(const [m180, m360], desktop: true)!;
    expect(choice.stream, m360);
    expect(choice.audioUrl, isNull);
  });

  test('desktop falls back to muxed when every stream has audio', () {
    final choice = pickDefaultStream(const [m360, m180, a128], desktop: true)!;
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
    expect(choice.audio, a128);
  });

  test('audio-only list still plays', () {
    final choice = pickDefaultStream(const [a128], desktop: true)!;
    expect(choice.stream, a128);
    expect(choice.audio, isNull);
  });

  test('empty stream list returns null', () {
    expect(pickDefaultStream(const [], desktop: true), isNull);
  });

  test('pairWithAudio attaches audio only when needed', () {
    expect(pairWithAudio(v720, const [a128]).audio, a128);
    expect(pairWithAudio(m360, const [a128]).audio, isNull);
  });

  test('pairWithAudio keeps the selected track', () {
    expect(pairWithAudio(v720, const [a64, a128], audio: a64).audio, a64);
    expect(pairWithAudio(v720, const [a128], audio: aDub).audio, aDub);
  });

  test('bestAudio prefers the video container', () {
    expect(bestAudio(const [aWebm, aMp4], container: 'mp4'), aMp4);
    expect(bestAudio(const [aWebm, aMp4], container: 'webm'), aWebm);
  });

  test('bestAudio falls back to any container', () {
    expect(bestAudio(const [aWebm], container: 'mp4'), aWebm);
    expect(bestAudio(const [a128], container: 'mp4'), a128);
  });

  test('pairWithAudio pairs audio from the same container', () {
    final choice = pairWithAudio(v1080mp4, const [aWebm, aMp4]);
    expect(choice.audio, aMp4);
  });

  test('pairWithAudio swaps an incompatible track', () {
    final choice = pairWithAudio(v1080mp4, const [aWebm, aMp4], audio: aWebm);
    expect(choice.audio, aMp4);
  });

  test('pairWithAudio keeps a compatible track', () {
    final choice = pairWithAudio(v1080mp4, const [aWebm, aMp4], audio: aMp4);
    expect(choice.audio, aMp4);
  });

  test('desktop pairs the matching audio container', () {
    const vWebm = PlayableStream(
      url: 'vWebm',
      quality: '2160p',
      hasAudio: false,
      container: 'webm',
    );
    final choice = pickDefaultStream(const [
      vWebm,
      v1080mp4,
      aMp4,
      aWebm,
    ], desktop: true)!;
    expect(choice.stream, vWebm);
    expect(choice.audio, aWebm);
  });
}
