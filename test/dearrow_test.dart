import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/dearrow.dart';
import 'package:newtube/services/dearrow_api.dart';
import 'package:newtube/state/settings_store.dart';

import 'fakes.dart';

void main() {
  group('DeArrowClient', () {
    test('picks the highest-voted title and thumbnail', () async {
      Uri? seen;
      final client = DeArrowClient(
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(
            jsonEncode({
              'titles': [
                {'title': 'Worse title', 'votes': 1},
                {'title': 'Better title', 'votes': 5},
                {'title': ''},
                {'bad': true},
              ],
              'thumbnails': [
                {'timestamp': 12.5, 'votes': 3},
                {'timestamp': 40.0, 'votes': 1},
                {'votes': 2},
                'junk',
              ],
            }),
            200,
          );
        }),
      );
      final result = await client.branding('vid1');
      expect(result!.title, 'Better title');
      expect(result.thumbnailUrl, contains('videoID=vid1'));
      expect(result.thumbnailUrl, contains('time=12.5'));
      expect(seen!.queryParameters['videoID'], 'vid1');
    });

    test('locked entries win over votes', () async {
      final client = DeArrowClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'titles': [
                {'title': 'Many votes', 'votes': 100},
                {'title': 'Locked', 'votes': 0, 'locked': true},
              ],
              'thumbnails': [
                {'timestamp': 5.0, 'votes': 9},
                {'timestamp': 7.0, 'votes': 0, 'locked': true},
              ],
            }),
            200,
          ),
        ),
      );
      final result = await client.branding('v');
      expect(result!.title, 'Locked');
      expect(result.thumbnailUrl, contains('time=7.0'));
    });

    test('returns null for unknown videos and junk bodies', () async {
      var body = 'not found';
      var status = 404;
      final client = DeArrowClient(
        client: MockClient((_) async => http.Response(body, status)),
      );
      expect(await client.branding('x'), isNull);
      body = '{}';
      status = 200;
      final empty = await client.branding('x');
      expect(empty!.title, isNull);
      expect(empty.thumbnailUrl, isNull);
      body = '{"titles": "junk", "thumbnails": "junk"}';
      final result = await client.branding('x');
      expect(result!.title, isNull);
      expect(result.thumbnailUrl, isNull);
    });

    test('throws on server errors', () async {
      final client = DeArrowClient(
        client: MockClient((_) async => http.Response('oops', 500)),
      );
      try {
        await client.branding('x');
        fail('should have thrown');
      } on DeArrowException catch (e) {
        expect(e.toString(), contains('500'));
      }
    });
  });

  group('DeArrowApi', () {
    DeArrowApi api({
      required http.Client client,
      DeArrowMode mode = DeArrowMode.both,
    }) => DeArrowApi(
      inner: FakeYouTubeApi(
        feed: testVideos,
        related: testVideos,
        uploads: testVideos,
        searchResults: const SearchResults(
          videos: testVideos,
          channels: [testChannel],
          playlists: [
            PlaylistInfo(id: 'pl1', title: 'Search mix', videoCount: 3),
          ],
        ),
      ),
      client: DeArrowClient(client: client),
      settings: SettingsStore(deArrowMode: mode),
    );

    MockClient branding({String? title, double? time, int status = 200}) =>
        MockClient((request) async {
          expect(request.url.path, endsWith('/api/branding'));
          return http.Response(
            jsonEncode({
              'titles': [
                if (title != null) {'title': title, 'votes': 1},
              ],
              'thumbnails': [
                if (time != null) {'timestamp': time, 'votes': 1},
              ],
            }),
            status,
          );
        });

    test('off mode never calls the API', () async {
      var calls = 0;
      final a = api(
        mode: DeArrowMode.off,
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      final videos = await a.homeFeed();
      expect(videos.first.title, 'First video');
      expect(calls, 0);
    });

    test('rewrites titles only in titles mode', () async {
      final a = api(
        mode: DeArrowMode.titles,
        client: branding(title: 'Honest title', time: 3.0),
      );
      final videos = await a.homeFeed();
      expect(videos.first.title, 'Honest title');
      expect(videos.first.thumbnailUrl, 'https://img.example.com/v1.jpg');
    });

    test('rewrites thumbnails only in thumbnails mode', () async {
      final a = api(
        mode: DeArrowMode.thumbnails,
        client: branding(title: 'Honest title', time: 3.0),
      );
      final videos = await a.homeFeed();
      expect(videos.first.title, 'First video');
      expect(videos.first.thumbnailUrl, contains('getThumbnail'));
    });

    test('rewrites details, search, related and uploads', () async {
      final a = api(client: branding(title: 'Honest title', time: 3.0));
      expect((await a.videoDetails('v1')).info.title, 'Honest title');
      expect((await a.relatedVideos('v1')).first.title, 'Honest title');
      expect((await a.channelVideos('c1')).first.title, 'Honest title');
      final results = await a.search('x');
      expect(results.videos.first.title, 'Honest title');
      expect(results.channels.first, testChannel);
      expect(results.playlists.single.title, 'Search mix');
      expect((await a.comments('v1')).comments, isEmpty);
      expect(await a.resolveChannel('https://www.youtube.com/@x'), isNull);
      expect((await a.playlist('pl1')).videos.first.title, 'Honest title');
      expect((await a.playlist('pl1')).title, 'Test playlist');
      expect(await a.channel('c1'), testChannel);
      const track = CaptionTrack(
        url: 'https://cap/en',
        languageCode: 'en',
        name: 'English',
      );
      expect(await a.captions(track), isEmpty);
      expect(await a.trending(), isEmpty);
      expect(await a.resolveUrl('https://youtu.be/x'), isNull);
      expect(await a.searchSuggestions('x'), isEmpty);
    });

    test('keeps the original when branding fails or is missing', () async {
      var a = api(client: branding(status: 404));
      expect((await a.homeFeed()).first.title, 'First video');
      a = api(client: MockClient((_) async => http.Response('oops', 500)));
      expect((await a.homeFeed()).first.title, 'First video');
    });
  });
}
