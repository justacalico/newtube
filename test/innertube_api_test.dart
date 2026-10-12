import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/services/youtube_api.dart';

Map<String, dynamic> _videoRenderer(String id, {String title = 'T'}) => {
  'videoRenderer': {
    'videoId': id,
    'title': {
      'runs': [
        {'text': title},
      ],
    },
    'ownerText': {
      'runs': [
        {
          'text': 'chan',
          'navigationEndpoint': {
            'browseEndpoint': {'browseId': 'UCabc'},
          },
        },
      ],
    },
    'thumbnail': {
      'thumbnails': [
        {'url': 'https://i/s.jpg'},
        {'url': 'https://i/l.jpg'},
      ],
    },
    'lengthText': {'simpleText': '1:02:03'},
    'viewCountText': {'simpleText': '1.5M views'},
    'publishedTimeText': {'simpleText': '2 days ago'},
  },
};

Map<String, dynamic> _lockup(String id, {String? author, String? channel}) => {
  'lockupViewModel': {
    'contentId': id,
    'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
    'contentImage': {
      'thumbnailViewModel': {
        'image': {
          'sources': [
            {'url': 'https://i/t.jpg', 'width': 100},
            {'width': 200},
            {'url': 'https://i/b.jpg', 'width': 300},
          ],
        },
        'overlays': [
          {
            'thumbnailBottomOverlayViewModel': {
              'badges': [
                {
                  'thumbnailBadgeViewModel': {'text': '10:16'},
                },
              ],
            },
          },
        ],
      },
    },
    'metadata': {
      'lockupMetadataViewModel': {
        'title': {'content': 'Lock $id'},
        'image': {
          'decoratedAvatarViewModel': {
            'avatar': {
              'rendererContext': {
                'commandContext': {
                  'onTap': {
                    'innertubeCommand': {
                      'browseEndpoint': {'browseId': channel ?? 'UCx'},
                    },
                  },
                },
              },
            },
          },
        },
        'metadata': {
          'contentMetadataViewModel': {
            'metadataRows': [
              {
                'metadataParts': [
                  if (author != null)
                    {
                      'text': {'content': author},
                    },
                  'skip',
                  {'text': 'nope'},
                  {
                    'text': {'content': '9M views'},
                  },
                  {
                    'text': {'content': '3 days ago'},
                  },
                ],
              },
              'not a map',
              {'metadataParts': 'nope'},
            ],
          },
        },
      },
    },
  },
};

InnertubeApi _api(
  Map<String, dynamic> Function(String endpoint, Map body) handler, {
  String? prefix,
}) {
  return InnertubeApi(
    proxyPrefix: prefix == null ? null : () => prefix,
    httpClient: MockClient((request) async {
      final endpoint = request.url.path.split('/').last.split('?').first;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final out = handler(endpoint, body);
      return http.Response.bytes(utf8.encode(jsonEncode(out)), 200);
    }),
  );
}

void main() {
  group('innertube api', () {
    test('homeFeed returns browse videos', () async {
      final api = _api((_, _) => {'x': _videoRenderer('v1')});
      final feed = await api.homeFeed();
      expect(feed.single.id, 'v1');
      expect(feed.single.title, 'T');
      expect(feed.single.duration, const Duration(seconds: 3723));
      expect(feed.single.viewCount, 1500000);
      expect(feed.single.uploaded, '2 days ago');
      expect(feed.single.thumbnailUrl, 'https://i/l.jpg');
    });

    test('homeFeed falls back to search on empty browse', () async {
      final api = _api(
        (endpoint, _) => endpoint == 'browse'
            ? <String, dynamic>{}
            : {'x': _videoRenderer('s1')},
      );
      expect((await api.homeFeed()).single.id, 's1');
    });

    test('homeFeed rethrows api errors', () async {
      final api = InnertubeApi(
        httpClient: MockClient((_) async => http.Response('x', 500)),
      );
      expect(api.homeFeed, throwsA(isA<InnertubeException>()));
    });

    test('homeFeed rethrows invalid body', () async {
      final api = InnertubeApi(
        httpClient: MockClient((_) async => http.Response('[1]', 200)),
      );
      expect(api.homeFeed, throwsA(isA<InnertubeException>()));
    });

    test('search returns videos and channels', () async {
      final api = _api(
        (_, _) => {
          'a': _videoRenderer('v'),
          'b': {
            'channelRenderer': {
              'channelId': 'UC1',
              'title': {'simpleText': 'Chan'},
              'thumbnail': {
                'thumbnails': [
                  {'url': 'https://i/c.jpg'},
                ],
              },
              'subscriberCountText': {'simpleText': '2M subscribers'},
            },
          },
        },
      );
      final r = await api.search('q');
      expect(r.videos.single.id, 'v');
      expect(r.channels.single.name, 'Chan');
      expect(r.channels.single.subscribers, 2000000);
    });

    test('videoDetails parses streams and skips ciphered', () async {
      final api = _api(
        (_, body) => {
          'videoDetails': {
            'title': 'Vid',
            'author': 'Auth',
            'channelId': 'UC9',
            'shortDescription': 'desc',
            'lengthSeconds': '61',
            'viewCount': '42',
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://i/v.jpg'},
              ],
            },
          },
          'streamingData': {
            'formats': [
              {
                'url': 'https://v/mux',
                'mimeType': 'video/mp4',
                'audioQuality': 'x',
                'qualityLabel': '360p',
              },
            ],
            'adaptiveFormats': [
              {
                'url': 'https://v/audio',
                'mimeType': 'audio/webm',
                'bitrate': 128000,
              },
              {
                'url': 'https://v/vid',
                'mimeType': 'video/mp4',
                'audioTrack': {},
                'qualityLabel': '1080p',
              },
              {'signatureCipher': 'x', 'qualityLabel': '720p'},
              'junk',
            ],
          },
        },
      );
      final d = await api.videoDetails('v');
      expect(d.info.title, 'Vid');
      expect(d.info.duration, const Duration(seconds: 61));
      expect(d.info.viewCount, 42);
      expect(d.description, 'desc');
      expect(d.streams.map((s) => s.quality), [
        '360p',
        'audio 128kbps',
        '1080p',
      ]);
      expect(d.streams[0].hasAudio, isTrue);
      expect(d.streams[1].hasVideo, isFalse);
      expect(d.streams[2].hasAudio, isTrue);
    });

    test('videoDetails throws without details', () async {
      final api = _api((_, _) => <String, dynamic>{});
      expect(() => api.videoDetails('x'), throwsA(isA<InnertubeException>()));
    });

    test('videoDetails defaults missing fields', () async {
      final api = _api((_, _) => {'videoDetails': <String, dynamic>{}});
      final d = await api.videoDetails('v');
      expect(d.info.title, '');
      expect(d.streams, isEmpty);
      expect(d.info.thumbnailUrl, isNull);
    });

    test('proxied streams and thumbnails get the prefix', () async {
      final api = _api(
        (_, _) => {
          'videoDetails': {'title': 'x'},
          'streamingData': {
            'formats': [
              {
                'url': 'https://v/x',
                'mimeType': 'video/mp4',
                'audioQuality': 'x',
              },
            ],
          },
        },
        prefix: 'https://p/?u=',
      );
      final d = await api.videoDetails('v');
      expect(d.streams.single.url, startsWith('https://p/?u='));
    });

    test('relatedVideos follows continuation', () async {
      var n = 0;
      final api = _api((endpoint, body) {
        n++;
        if (body.containsKey('continuation')) {
          return {'x': _lockup('r1', author: 'A'), 'y': _lockup('watched')};
        }
        return {
          'contents': {
            'twoColumnWatchNextResults': {
              'secondaryResults': {
                'secondaryResults': {
                  'results': [
                    {'z': _lockup('seed', author: 'B')},
                    {
                      'continuationItemRenderer': {
                        'continuationEndpoint': {
                          'continuationCommand': {'token': 'tok'},
                        },
                      },
                    },
                  ],
                },
              },
            },
          },
        };
      });
      final r = await api.relatedVideos('watched');
      expect(n, 2);
      expect(r.map((v) => v.id), ['seed', 'r1']);
      expect(r.first.author, 'B');
      expect(r.first.channelId, 'UCx');
      expect(r.first.duration, const Duration(minutes: 10, seconds: 16));
      expect(r.first.thumbnailUrl, 'https://i/b.jpg');
      expect(r.first.viewCount, 9000000);
      expect(r.first.uploaded, '3 days ago');
    });

    test('relatedVideos without secondary results parses body', () async {
      final api = _api((_, _) => {'v': _lockup('o', author: 'a')});
      expect((await api.relatedVideos('x')).single.id, 'o');
    });

    test('relatedVideos handles list-shaped lockup metadata', () async {
      final api = _api(
        (_, _) => {
          'v': {
            'lockupViewModel': {
              'contentId': 'li',
              'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
              'contentImage': {
                'thumbnailViewModel': {
                  'image': {
                    'sources': [
                      {'url': 'https://i/x.jpg'},
                    ],
                  },
                },
              },
              'metadata': {
                'lockupMetadataViewModel': {
                  'title': {'content': 'L'},
                  'image': [
                    {
                      'browseEndpoint': {'browseId': 'UClist'},
                    },
                  ],
                  'metadata': [
                    {
                      'contentMetadataViewModel': {'metadataRows': []},
                    },
                  ],
                },
              },
            },
          },
        },
      );
      final v = (await api.relatedVideos('z')).single;
      expect(v.id, 'li');
      expect(v.channelId, 'UClist');
      expect(v.thumbnailUrl, 'https://i/x.jpg');
    });

    test('default constructor works without a client', () {
      expect(InnertubeApi(), isA<YouTubeApi>());
    });

    test('channel parses metadata and subscriber text', () async {
      final api = _api(
        (_, _) => {
          'metadata': {
            'channelMetadataRenderer': {
              'title': 'Chan',
              'avatar': {
                'thumbnails': [
                  {'url': 'https://i/a.jpg'},
                ],
              },
            },
          },
          'header': {
            'x': {
              'subtitle': {'content': '@chan • 20.7M subscribers'},
            },
          },
        },
      );
      final c = await api.channel('UC1');
      expect(c.name, 'Chan');
      expect(c.subscribers, 20700000);
      expect(c.thumbnailUrl, 'https://i/a.jpg');
    });

    test('channel falls back to header avatar', () async {
      final api = _api(
        (_, _) => {
          'metadata': {
            'channelMetadataRenderer': {'title': 'C'},
          },
          'header': {
            'wrap': [
              {
                'avatar': {
                  'thumbnails': [
                    {'url': 'https://i/h.jpg'},
                  ],
                },
              },
            ],
          },
        },
      );
      final c = await api.channel('UC1');
      expect(c.thumbnailUrl, 'https://i/h.jpg');
      expect(c.subscribers, 0);
    });

    test('channel throws without metadata', () async {
      final api = _api((_, _) => <String, dynamic>{});
      expect(() => api.channel('x'), throwsA(isA<InnertubeException>()));
    });

    test('channelVideos uses videos tab params', () async {
      final api = _api((endpoint, body) {
        if (body['params'] == 'tab') return {'v': _lockup('tv', author: 'a')};
        return {
          'contents': {
            'twoColumnBrowseResultsRenderer': {
              'tabs': [
                {
                  'tabRenderer': {
                    'title': 'Videos',
                    'endpoint': {
                      'browseEndpoint': {'params': 'tab'},
                    },
                  },
                },
              ],
            },
          },
        };
      });
      expect((await api.channelVideos('UC1')).single.id, 'tv');
    });

    test('channelVideos falls back to base browse', () async {
      final api = _api((endpoint, body) {
        if (body.containsKey('params')) return <String, dynamic>{};
        return {'w': _videoRenderer('base')};
      });
      expect((await api.channelVideos('UC1')).single.id, 'base');
    });

    test('channelVideos fills in a missing channel id', () async {
      final api = _api(
        (_, _) => {
          'w': {
            'compactVideoRenderer': {'videoId': 'c'},
          },
        },
      );
      final video = (await api.channelVideos('UC1')).single;
      expect(video.channelId, 'UC1');
      expect(video.author, '');
    });

    test('channelVideos without matching tab uses base browse', () async {
      final api = _api(
        (_, _) => {
          'contents': {
            'tabs': [
              {
                'tabRenderer': {'title': 'Videos', 'endpoint': 'nope'},
              },
              {
                'tabRenderer': {'title': 'Video', 'endpoint': {}},
              },
              {
                'tabRenderer': {
                  'title': 'Video',
                  'endpoint': {
                    'browseEndpoint': {'params': 5},
                  },
                },
              },
              {
                'tabRenderer': {'title': 'Home'},
              },
            ],
          },
          'v': _videoRenderer('x'),
        },
      );
      expect((await api.channelVideos('UC1')).single.id, 'x');
    });

    test('InnertubeException toString', () {
      expect(
        const InnertubeException('oops').toString(),
        'InnertubeException: oops',
      );
    });
  });

  group('parsers', () {
    test('innertubeContext clients', () {
      expect(innertubeContext()['client']['clientName'], 'WEB');
      expect(
        innertubeContext(client: 'ANDROID')['client']['clientName'],
        'ANDROID',
      );
    });

    test('collectVideos picks compact and lockup', () {
      final out = <VideoInfo>[];
      collectVideos({
        'a': {
          'compactVideoRenderer': {'videoId': 'c1'},
        },
        'b': _lockup('l1'),
        'c': [_videoRenderer('v1')],
        'd': {'lockupViewModel': 'junk'},
        'e': {
          'lockupViewModel': {'contentType': 'OTHER', 'contentId': 'x'},
        },
      }, out);
      expect(out.map((v) => v.id), ['c1', 'l1', 'v1']);
    });

    test('collectChannels recursion and misses', () {
      final out = <ChannelInfo>[];
      collectChannels([
        {
          'x': {'channelRenderer': 'junk'},
        },
        {
          'channelRenderer': {'channelId': 5},
        },
      ], out);
      expect(out, isEmpty);
      collectChannels('str', out);
      expect(out, isEmpty);
    });

    test('continuationToken finds nested tokens', () {
      expect(
        continuationToken({
          'a': [
            {
              'b': {
                'continuationCommand': {'token': 'T'},
              },
            },
          ],
        }),
        'T',
      );
      expect(
        continuationToken({
          'c': {
            'continuationCommand': {'token': 1},
          },
        }),
        isNull,
      );
      expect(continuationToken('x'), isNull);
    });

    test('parseLockup edge cases', () {
      expect(parseLockup({'contentType': 'X', 'contentId': 'a'}), isNull);
      expect(parseLockup({'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO'}), isNull);
      final bare = parseLockup({
        'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
        'contentId': 'i',
        'metadata': 'junk',
      });
      expect(bare!.title, '');
      final noLmd = parseLockup({
        'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
        'contentId': 'i',
        'metadata': {'lockupMetadataViewModel': 'junk'},
      });
      expect(noLmd!.channelId, '');
    });

    test('compactCount formats', () {
      expect(compactCount(''), 0);
      expect(compactCount('12K views'), 12000);
      expect(compactCount('3.5M'), 3500000);
      expect(compactCount('1B'), 1000000000);
      expect(compactCount('1,234 views'), 1234);
      expect(compactCount('views'), 0);
      expect(compactCount('@h • 20.7M subscribers'), 20700000);
    });

    test('runs and browseId edge cases', () {
      expect(runs('x'), isNull);
      expect(runs({'simpleText': 'a'}), 'a');
      expect(runs({'runs': []}), '');
      expect(browseId('x'), isNull);
      expect(browseId({'runs': 'x'}), isNull);
      expect(
        browseId({
          'runs': [5],
        }),
        isNull,
      );
      expect(
        browseId({
          'runs': [
            {'navigationEndpoint': 'x'},
          ],
        }),
        isNull,
      );
      expect(
        browseId({
          'runs': [
            {
              'navigationEndpoint': {'browseEndpoint': 'x'},
            },
          ],
        }),
        isNull,
      );
      expect(
        browseId({
          'runs': [
            {
              'navigationEndpoint': {
                'browseEndpoint': {'browseId': 1},
              },
            },
          ],
        }),
        isNull,
      );
    });

    test('thumbnail and duration edge cases', () {
      expect(thumbnail('x'), isNull);
      expect(thumbnail({'thumbnails': 'x'}), isNull);
      expect(
        thumbnail({
          'thumbnails': [1],
        }),
        isNull,
      );
      expect(
        thumbnail({
          'thumbnails': [
            {'url': 2},
          ],
        }),
        isNull,
      );
      expect(duration({'simpleText': 'x:y'}), isNull);
      expect(duration({'simpleText': '2:05'}), const Duration(seconds: 125));
    });
  });
}
