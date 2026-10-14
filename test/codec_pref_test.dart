import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/utils/stream_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:newtube/state/settings_store.dart';

void main() {
  const avc = PlayableStream(
    url: 'a',
    quality: '720p',
    mimeType: 'video/mp4; codecs="avc1.64001F"',
    height: 720,
  );
  const av1 = PlayableStream(
    url: 'b',
    quality: '720p',
    mimeType: 'video/mp4; codecs="av01.0.09M.08"',
    height: 720,
  );
  const vp9 = PlayableStream(
    url: 'c',
    quality: '1080p',
    mimeType: 'video/webm; codecs="vp09.00.51.08"',
    height: 1080,
  );

  test('streamCodec parses mimeType', () {
    expect(streamCodec(avc), 'avc');
    expect(streamCodec(vp9), 'vp9');
    expect(streamCodec(av1), 'av1');
    expect(streamCodec(const PlayableStream(url: 'x', quality: 'q')), isNull);
  });

  test('codec preference filters to matching codec', () {
    final pick = pickDefaultStream(
      [avc, vp9],
      desktop: false,
      preferredCodec: 1,
    );
    expect(pick?.stream.url, 'a');

    final none = pickDefaultStream([vp9], desktop: false, preferredCodec: 1);
    expect(none?.stream.url, 'c');
  });

  test('preferredCodec persists', () async {
    SharedPreferences.setMockInitialValues({'preferred_codec': 3});
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsStore.load(prefs);
    expect(settings.preferredCodec, 3);
    await settings.setPreferredCodec(1, prefs);
    expect(prefs.getInt('preferred_codec'), 1);
  });
}
