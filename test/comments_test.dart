import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/ui/pages/channel_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

Map<String, dynamic> _nextPage() => {
  'contents': {
    'twoColumnWatchNextResults': {
      'results': {
        'results': {
          'contents': [
            {
              'itemSectionRenderer': {
                'contents': [
                  {'commentsEntryPointHeaderRenderer': {}},
                  {
                    'continuationItemRenderer': {
                      'continuationEndpoint': {
                        'continuationCommand': {'token': 'ctok'},
                      },
                    },
                  },
                ],
              },
            },
          ],
        },
      },
    },
  },
};

Map<String, dynamic> _thread({
  required String author,
  required String text,
  String likes = '1.2K',
  bool pinned = false,
  bool hearted = false,
  int replies = 0,
}) => {
  'commentThreadRenderer': {
    'comment': {
      'commentRenderer': {
        'authorText': {'simpleText': author},
        'authorEndpoint': {
          'browseEndpoint': {'browseId': 'UCa'},
        },
        'contentText': {
          'runs': [
            {'text': text},
          ],
        },
        'voteCount': {'simpleText': likes},
        'publishedTimeText': {'simpleText': '2 weeks ago'},
        'authorThumbnail': {
          'thumbnails': [
            {'url': 'https://i/a.jpg'},
          ],
        },
        if (pinned) 'pinnedCommentBadge': {'pinnedCommentBadgeRenderer': {}},
        if (hearted)
          'authorCommentBadge': {
            'authorCommentBadgeRenderer': {
              'icon': {
                'nested': [
                  {'iconType': 'HEART'},
                ],
              },
            },
          },
      },
    },
    if (replies > 0)
      'replies': {
        'commentRepliesRenderer': {
          'contents': [
            {
              'viewReplies': {
                'buttonText': {'simpleText': '$replies replies'},
              },
            },
          ],
        },
      },
  },
};

Map<String, dynamic> _commentsPage(
  List<Map<String, dynamic>> threads, {
  String? next,
}) => {
  'onResponseReceivedEndpoints': [
    {
      'appendContinuationItemsAction': {
        'continuationItems': [
          ...threads,
          if (next != null)
            {
              'continuationItemRenderer': {
                'continuationEndpoint': {
                  'continuationCommand': {'token': next},
                },
              },
            },
        ],
      },
    },
  ],
};

InnertubeApi _api(
  Map<String, dynamic> Function(String endpoint, Map body) handler,
) => InnertubeApi(
  httpClient: MockClient((request) async {
    if (request.method != 'POST') return http.Response.bytes(const [], 206);
    final endpoint = request.url.path.split('/').last.split('?').first;
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    return http.Response.bytes(
      utf8.encode(jsonEncode(handler(endpoint, body))),
      200,
    );
  }),
);

void main() {
  group('innertube comments', () {
    test('fetches the first page of comments', () async {
      final api = _api(
        (endpoint, body) => body.containsKey('continuation')
            ? _commentsPage([
                _thread(
                  author: 'Alice',
                  text: 'Nice video',
                  pinned: true,
                  hearted: true,
                  replies: 3,
                ),
                _thread(author: 'Bob', text: 'second', likes: '5'),
                {'junkItem': {}},
              ], next: 'tok2')
            : _nextPage(),
      );
      final result = await api.comments('v1');
      expect(result.comments, hasLength(2));
      final first = result.comments.first;
      expect(first.author, 'Alice');
      expect(first.text, 'Nice video');
      expect(first.likeCount, 1200);
      expect(first.published, '2 weeks ago');
      expect(first.channelId, 'UCa');
      expect(first.avatarUrl, 'https://i/a.jpg');
      expect(first.pinned, isTrue);
      expect(first.hearted, isTrue);
      expect(first.replyCount, 3);
      expect(result.comments[1].pinned, isFalse);
      expect(result.comments[1].hearted, isFalse);
      expect(result.continuation, 'tok2');
    });

    test('fetches the next page via continuation', () async {
      var sawNext = false;
      final api = _api((endpoint, body) {
        if (body['continuation'] == 'tok2') {
          sawNext = true;
          return _commentsPage([_thread(author: 'Carol', text: 'more')]);
        }
        return _nextPage();
      });
      final result = await api.comments('v1', continuation: 'tok2');
      expect(sawNext, isTrue);
      expect(result.comments.single.author, 'Carol');
      expect(result.continuation, isNull);
    });

    test('continuation pages parse bare comment replies', () async {
      final api = _api(
        (endpoint, body) => _commentsPage([
          {
            'commentRenderer': {
              'authorText': {
                'runs': [
                  {'text': 'Replier'},
                ],
              },
              'contentText': {
                'runs': [
                  {'text': 'a reply'},
                ],
              },
            },
          },
        ]),
      );
      final result = await api.comments('v1', continuation: 'replytok');
      expect(result.comments.single.author, 'Replier');
      expect(result.comments.single.text, 'a reply');
    });

    test('reloadContinuationItemsCommand is also parsed', () async {
      final api = _api(
        (endpoint, body) => {
          'onResponseReceivedEndpoints': [
            {
              'reloadContinuationItemsCommand': {
                'continuationItems': [_thread(author: 'D', text: 'x')],
              },
            },
          ],
        },
      );
      final result = await api.comments('v', continuation: 't');
      expect(result.comments.single.author, 'D');
    });

    test('returns empty when the video has no comments section', () async {
      final api = _api((_, _) => {'contents': {}});
      expect((await api.comments('v')).comments, isEmpty);
    });

    test('returns empty when the response has no endpoints', () async {
      final api = _api((_, _) => {'other': true});
      expect((await api.comments('v', continuation: 't')).comments, isEmpty);
    });
  });

  group('watch page comments', () {
    const comment = CommentInfo(
      author: 'Alice',
      channelId: 'c1',
      text: 'First!',
      likeCount: 42,
      published: '1 day ago',
      pinned: true,
      hearted: true,
      replyCount: 2,
    );

    testWidgets('shows comments and loads the next page', (tester) async {
      final api = FakeYouTubeApi(
        commentsResult: const CommentsResult(
          comments: [
            comment,
            CommentInfo(author: 'Anon', text: 'no channel link'),
          ],
          continuation: 'tok',
        ),
        commentPages: const {
          'tok': CommentsResult(
            comments: [CommentInfo(author: 'Bob', text: 'Second')],
          ),
        },
      );
      final state = await testState(api: api, player: FakePlayerController());
      await pumpPage(tester, state, WatchPage(video: testVideos.first));
      await tester.pumpAndSettle();

      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('First!'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('2 replies'), findsOneWidget);

      await tester.ensureVisible(find.text('Load more comments'));
      await tester.ensureVisible(find.text('Load more comments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load more comments'));
      await tester.pumpAndSettle();
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Load more comments'), findsNothing);
    });

    testWidgets('comment author opens the channel page', (tester) async {
      final api = FakeYouTubeApi(
        commentsResult: const CommentsResult(comments: [comment]),
        uploads: testVideos,
      );
      final state = await testState(api: api, player: FakePlayerController());
      await pumpPage(tester, state, WatchPage(video: testVideos.first));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.byType(ChannelPage), findsOneWidget);
    });

    testWidgets('load more failure keeps existing comments', (tester) async {
      final api = _PagingFailApi();
      final state = await testState(api: api, player: FakePlayerController());
      await pumpPage(tester, state, WatchPage(video: testVideos.first));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Load more comments'));
      await tester.ensureVisible(find.text('Load more comments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load more comments'));
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Load more comments'), findsOneWidget);
    });

    testWidgets('comments failure still plays the video', (tester) async {
      final api = _CommentsFailApi();
      final state = await testState(api: api, player: FakePlayerController());
      await pumpPage(tester, state, WatchPage(video: testVideos.first));
      await tester.pumpAndSettle();
      expect(find.text('Comments'), findsNothing);
      expect(find.text('First video'), findsWidgets);
    });
  });
}

class _PagingFailApi extends FakeYouTubeApi {
  _PagingFailApi()
    : super(
        commentsResult: const CommentsResult(
          comments: [CommentInfo(author: 'Alice', text: 'hi')],
          continuation: 'tok',
        ),
      );

  @override
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  }) async =>
      continuation == null ? commentsResult : throw StateError('paging fail');
}

class _CommentsFailApi extends FakeYouTubeApi {
  @override
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  }) async => throw StateError('nope');
}
