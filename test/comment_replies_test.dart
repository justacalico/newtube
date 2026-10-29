import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/ui/pages/watch_page.dart';

import 'fakes.dart';

void main() {
  test('comments parse reply continuation and owner badge', () async {
    final calls = <String>[];
    final api = InnertubeApi(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        calls.add(body['continuation'] as String? ?? '');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'onResponseReceivedEndpoints': [
                {
                  'appendContinuationItemsAction': {
                    'continuationItems': [
                      {
                        'commentThreadRenderer': {
                          'comment': {
                            'commentRenderer': {
                              'authorText': {
                                'runs': [
                                  {'text': 'Ann'},
                                ],
                              },
                              'contentText': {
                                'runs': [
                                  {'text': 'top comment'},
                                ],
                              },
                              'authorIsChannelOwner': true,
                            },
                          },
                          'replies': {
                            'commentRepliesRenderer': {
                              'contents': [
                                {
                                  'continuationItemRenderer': {
                                    'continuationEndpoint': {
                                      'continuationCommand': {
                                        'token': 'replytok',
                                      },
                                    },
                                  },
                                },
                              ],
                            },
                          },
                        },
                      },
                      {
                        'continuationItemRenderer': {
                          'continuationEndpoint': {
                            'continuationCommand': {'token': 'more'},
                          },
                        },
                      },
                    ],
                  },
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    final result = await api.comments('v1', continuation: 'start');
    expect(calls, ['start']);
    expect(result.comments.single.isOwner, isTrue);
    expect(result.comments.single.replyContinuation, 'replytok');
    expect(result.continuation, 'more');
  });

  test('sort continuation overrides the comments token', () async {
    final calls = <String>[];
    final api = InnertubeApi(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        calls.add(body['continuation'] as String? ?? '');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'itemSectionContinuation': {
                'contents': [
                  {
                    'itemSectionRenderer': {
                      'header': {
                        'commentsHeaderRenderer': <String, dynamic>{},
                        'commentsEntryPointHeaderRenderer': <String, dynamic>{},
                      },
                      'continuationCommands': [
                        {
                          'continuationEndpoint': {
                            'continuationCommand': {'token': 'comments-tok'},
                          },
                        },
                      ],
                    },
                  },
                ],
                'footer': {
                  'sortMenu': {
                    'sortMenuRenderer': {
                      'sortItems': [
                        {
                          'serviceEndpoint': {
                            'continuationCommand': {'token': 'sort-top'},
                          },
                        },
                        {
                          'serviceEndpoint': {
                            'continuationCommand': {'token': 'sort-newest'},
                          },
                        },
                      ],
                    },
                  },
                },
              },
              'onResponseReceivedEndpoints': [
                {
                  'appendContinuationItemsAction': {
                    'continuationItems': <dynamic>[],
                  },
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    await api.comments('v1', sort: CommentSort.newest);
    expect(calls, ['', 'sort-newest']);
  });

  testWidgets('reply toggle loads replies on demand', (tester) async {
    final api = FakeYouTubeApi(
      feed: testVideos,
      commentsResult: const CommentsResult(
        comments: [
          CommentInfo(
            author: 'Ann',
            text: 'top comment',
            replyCount: 1,
            replyContinuation: 'replytok',
            isOwner: true,
          ),
        ],
      ),
      commentPages: {
        'replytok': const CommentsResult(
          comments: [CommentInfo(author: 'Bob', text: 'a reply')],
        ),
      },
    );
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Show replies'));
    await tester.pumpAndSettle();
    expect(find.text('Creator'), findsOneWidget);
    await tester.tap(find.text('Show replies'));
    await tester.pumpAndSettle();
    expect(find.text('a reply'), findsOneWidget);
    await tester.tap(find.text('Hide replies'));
    await tester.pumpAndSettle();
    expect(find.text('a reply'), findsNothing);
  });

  testWidgets('sort menu refetches comments', (tester) async {
    final api = FakeYouTubeApi(
      feed: testVideos,
      commentsResult: const CommentsResult(
        comments: [CommentInfo(author: 'Ann', text: 'first')],
      ),
    );
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sort comments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort comments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest'));
    await tester.pumpAndSettle();
    expect(api.commentSortCalls, contains(CommentSort.newest));
  });

  testWidgets('reply load failure clears the spinner', (tester) async {
    final api = FakeYouTubeApi(
      feed: testVideos,
      commentsResult: const CommentsResult(
        comments: [
          CommentInfo(
            author: 'Ann',
            text: 'top',
            replyCount: 1,
            replyContinuation: 'replytok',
          ),
        ],
      ),
    )..failingCommentPages = {'replytok'};
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Show replies'));
    await tester.tap(find.text('Show replies'));
    await tester.pumpAndSettle();
    expect(find.text('Show replies'), findsOneWidget);
  });

  testWidgets('replies re-expand after collapsing', (tester) async {
    final api = FakeYouTubeApi(
      feed: testVideos,
      commentsResult: const CommentsResult(
        comments: [
          CommentInfo(
            author: 'Ann',
            text: 'top',
            replyCount: 1,
            replyContinuation: 'replytok',
          ),
        ],
      ),
      commentPages: {
        'replytok': const CommentsResult(
          comments: [CommentInfo(author: 'Bob', text: 'a reply')],
        ),
      },
    );
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Show replies'));
    await tester.tap(find.text('Show replies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide replies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show replies'));
    await tester.pumpAndSettle();
    expect(find.text('a reply'), findsOneWidget);
    expect(api.commentSortCalls.where((c) => c == null).length, greaterThan(0));
  });

  testWidgets('sort failure keeps existing comments', (tester) async {
    final api = FakeYouTubeApi(
      feed: testVideos,
      commentsResult: const CommentsResult(
        comments: [CommentInfo(author: 'Ann', text: 'first')],
      ),
    )..failingSorts = {CommentSort.newest};
    final state = await testState(api: api);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sort comments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort comments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort comments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort comments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
  });
}
