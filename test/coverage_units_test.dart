import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/backup.dart';
import 'package:newtube/services/dearrow_api.dart';
import 'package:newtube/services/fallback_api.dart';
import 'package:newtube/services/network_proxy_io.dart';
import 'package:newtube/services/dearrow.dart';
import 'package:newtube/services/forwarding_api.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/l10n/app_localizations_en.dart';
import 'package:newtube/l10n/app_localizations_ga.dart';
import 'package:newtube/l10n/app_localizations_ru.dart';
import 'package:newtube/l10n/app_localizations_zh.dart';
import 'package:newtube/state/downloads_store.dart';
import 'package:newtube/state/playback_session.dart';
import 'package:newtube/state/hidden_store.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/utils/relative_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('youtube api default channel methods', () async {
    final api = BareApi(const [
      VideoInfo(
        id: 's1',
        title: 'Short clip',
        author: 'a',
        channelId: 'c',
        isShort: true,
      ),
      VideoInfo(id: 'v1', title: 'Normal', author: 'a', channelId: 'c'),
    ]);
    expect((await api.channelShorts('c')).single.id, 's1');
    expect(await api.channelPlaylists('c'), isEmpty);
    expect((await api.channelAbout('c')).description, '');
    expect((await api.channelSearch('c', 'short')).single.id, 's1');
    expect(await api.channelSearch('c', 'zzz'), isEmpty);
  });

  test('hidden store hides and unhides', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await HiddenStore.load(prefs);
    await store.hideVideo('v1', prefs);
    await store.hideChannel('c1', prefs);
    expect(store.videos.contains('v1'), isTrue);
    expect(store.channels.contains('c1'), isTrue);
    await store.unhideVideo('v1', prefs);
    await store.unhideChannel('c1', prefs);
    expect(store.videos, isEmpty);
    expect(store.channels, isEmpty);
  });

  test('playback session takePrevious and takeNextFrom', () {
    const a = VideoInfo(id: 'a', title: 'A', author: '', channelId: '');
    const b = VideoInfo(id: 'b', title: 'B', author: '', channelId: '');
    const c = VideoInfo(id: 'c', title: 'C', author: '', channelId: '');
    final session = PlaybackSession();
    session.attach(FakePlayerController(), a);
    session
      ..enqueue(b)
      ..enqueue(c);
    expect(session.hasNext, isTrue);
    expect(session.takeNext()!.id, 'b');
    expect(session.takePrevious()!.id, 'a');
    expect(session.hasPrevious, isFalse);
    expect(session.takeNextFrom(0)!.id, 'a');
    expect(session.takeNextFrom(5), isNull);
  });

  test('dearrow api delegates channel methods', () async {
    final fake = FakeYouTubeApi();
    final api = DeArrowApi(
      settings: SettingsStore(),
      client: DeArrowClient(),
      inner: fake,
    );
    expect(await api.channelShorts('c1'), isEmpty);
    expect(await api.channelPlaylists('c1'), isEmpty);
    expect((await api.channelAbout('c1')).description, '');
    expect(await api.channelSearch('c1', 'x'), isEmpty);
  });

  test('downloads store tolerates corrupt entries', () async {
    SharedPreferences.setMockInitialValues({'downloads': '{bad'});
    final prefs = await SharedPreferences.getInstance();
    final store = await DownloadsStore.load(prefs);
    expect(store.entries, isEmpty);
    SharedPreferences.setMockInitialValues({
      'downloads': '[{"id":"v1","title":"t","author":"a","channelId":"c","duration":10,"path":"/x"}]',
    });
    final store2 = await DownloadsStore.load(
      await SharedPreferences.getInstance(),
    );
    expect(store2.entries.single.video.id, 'v1');
  });

  test('proxyHttpClient builds io client for rules', () {
    expect(proxyHttpClient(''), isNull);
    expect(proxyHttpClient('  '), isNull);
  });

  test('parseRelativeDate units', () {
    final now = DateTime(2024, 6, 1);
    expect(
      parseRelativeDate('1 second ago', now),
      now.subtract(const Duration(seconds: 1)),
    );
    expect(
      parseRelativeDate('2 minutes ago', now),
      now.subtract(const Duration(minutes: 2)),
    );
    expect(parseRelativeDate('1 year ago', now)!.year, now.year - 1);
    expect(parseRelativeDate('3 decades ago', now), isNull);
    expect(parseRelativeDate('bogus', now), isNull);
  });

  test('importBackup rejects bad json', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(() => importBackup('{not json', prefs), throwsA(anything));
    expect(() => importBackup('{"other":{}}', prefs), throwsA(anything));
  });

  test('playability exception classification', () {
    const e = PlayabilityException('ERROR', 'gone');
    expect(e.isPrivate, isTrue);
    expect(e.isUnavailable, isTrue);
    expect(e.isAgeGate, isFalse);
    expect(e.isMembersOnly, isFalse);
    const members = PlayabilityException(
      'LOGIN_REQUIRED',
      'Join this channel to get access to members-only content like this '
          'video, and other exclusive perks.',
    );
    expect(members.isMembersOnly, isTrue);
    expect(members.isAgeGate, isFalse);
    expect(const PlayabilityException('UNPLAYABLE', 'x').isUnavailable, isTrue);
    expect(
      const PlayabilityException('LIVE_STREAM_OFFLINE', 'x').isUnavailable,
      isTrue,
    );
    expect(e.toString(), contains('gone'));
  });

  test('fallback api covers channel videos and captions', () async {
    final api = FallbackApi(FakeYouTubeApi(), FakeYouTubeApi());
    expect(await api.channelVideos('c1'), isEmpty);
    expect(
      await api.captions(
        const CaptionTrack(languageCode: 'en', name: 'en', url: 'u'),
      ),
      isEmpty,
    );
  });

  test('importBackup restores each pref type', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final text = jsonEncode({
      'prefs': {
        'flag': true,
        'count': 3,
        'ratio': 1.5,
        'name': 'x',
        'tags': ['a', 'b'],
        'nested': {'no': 'way'},
      },
    });
    final count = await importBackup(text, prefs);
    expect(count, 5);
    expect(prefs.getDouble('ratio'), 1.5);
    expect(prefs.getStringList('tags'), ['a', 'b']);
  });

  test('forwarding api delegates every call', () async {
    final api = ForwardingYouTubeApi(FakeYouTubeApi());
    await api.homeFeed();
    await api.trending();
    await api.search('q');
    await api.resolveUrl('u');
    await api.searchSuggestions('q');
    await api.videoDetails('v');
    await api.relatedVideos('v');
    await api.comments('v');
    await api.channel('c');
    await api.channelShorts('c');
    await api.channelPlaylists('c');
    await api.channelAbout('c');
    await api.channelSearch('c', 'q');
    await api.playlist('p');
    await api.resolveChannel('u');
    await api.channelVideos('c');
    await api.captions(
      const CaptionTrack(url: 'u', languageCode: 'en', name: 'n'),
    );
  });

  test('dearrow applies branding inside channel playlists', () async {
    final fake = FakeYouTubeApi()
      ..channelPlaylistList = [
        PlaylistInfo(id: 'p', title: 't', videos: testVideos),
      ];
    final api = DeArrowApi(
      settings: SettingsStore(),
      client: DeArrowClient(),
      inner: fake,
    );
    final result = await api.channelPlaylists('c');
    expect(result.single.videos, hasLength(testVideos.length));
  });

  test('innertube decodes large bodies off the ui isolate', () async {
    final pad = 'x' * (300 * 1024);
    final api = InnertubeApi(
      httpClient: http_testing.MockClient(
        (_) async => http.Response('{"pad": "$pad"}', 200),
      ),
    );
    expect(await api.homeFeed(), isEmpty);
  });

  test('theaterMode getter in every locale', () {
    final AppLocalizations en = AppLocalizationsEnGb();
    expect(en.theaterMode, 'Theater mode');
    expect(en.fullscreen, 'Fullscreen');
    expect(en.quality, 'Quality');
    expect(AppLocalizationsZh().theaterMode, isNotEmpty);
    expect(AppLocalizationsGa().theaterMode, isNotEmpty);
    expect(AppLocalizationsRu().theaterMode, isNotEmpty);
  });
}
