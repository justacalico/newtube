import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:newtube/l10n/app_localizations.dart';
import 'package:newtube/services/file_saver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/app_update.dart';
import 'package:newtube/models/search_filter.dart';
import 'package:newtube/models/youtube_route.dart';
import 'package:newtube/services/links.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/brightness.dart';
import 'package:newtube/services/mcp_server.dart';
import 'package:newtube/services/player_controller.dart';
import 'package:newtube/services/sponsor_block.dart';
import 'package:newtube/services/media_controls.dart';
import 'package:newtube/services/orientation.dart';
import 'package:newtube/services/pip_actions.dart';
import 'package:newtube/services/ryd.dart';
import 'package:newtube/services/share.dart';
import 'package:newtube/services/uploads_watcher.dart';
import 'package:newtube/services/version_checker.dart';
import 'package:newtube/services/window_actions.dart';
import 'package:newtube/services/youtube_api.dart';
import 'package:newtube/services/downloads.dart';
import 'package:newtube/state/app_state.dart';
import 'package:newtube/state/downloads_store.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/state/playlists_store.dart';
import 'package:newtube/state/search_history_store.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/state/watch_later_store.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testVideos = [
  VideoInfo(
    id: 'v1',
    title: 'First video',
    author: 'Channel One',
    channelId: 'c1',
    thumbnailUrl: 'https://img.example.com/v1.jpg',
    duration: Duration(minutes: 3, seconds: 21),
    viewCount: 12345,
    uploaded: '2 days ago',
  ),
  VideoInfo(
    id: 'v2',
    title: 'Second video',
    author: 'Channel Two',
    channelId: 'c2',
    viewCount: 0,
  ),
];

const testStreams = [
  PlayableStream(
    url: 'https://video.example.com/720',
    quality: '720p',
    hasAudio: false,
  ),
  PlayableStream(url: 'https://video.example.com/360', quality: '360p'),
  PlayableStream(
    url: 'https://audio.example.com/128',
    quality: 'audio 128kbps',
    hasVideo: false,
  ),
];

const testChannel = ChannelInfo(
  id: 'c1',
  name: 'Channel One',
  thumbnailUrl: 'https://img.example.com/c1.jpg',
  subscribers: 54321,
);

class FakeYouTubeApi implements YouTubeApi {
  Object? error;
  Completer<VideoDetails>? detailsGate;
  List<VideoInfo> feed;
  SearchResults searchResults;
  VideoDetails? details;
  List<VideoInfo> related;
  ChannelInfo channelInfo;
  List<VideoInfo> uploads;
  CommentsResult commentsResult;
  Map<String, CommentsResult> commentPages;
  List<VideoInfo> trendingFeed;
  final commentSortCalls = <CommentSort?>[];
  Set<CommentSort> failingSorts = const {};
  Set<String> failingCommentPages = const {};

  FakeYouTubeApi({
    this.feed = const [],
    this.searchResults = const SearchResults(),
    this.details,
    this.related = const [],
    this.channelInfo = testChannel,
    this.uploads = const [],
    this.commentsResult = const CommentsResult(),
    this.commentPages = const {},
    this.trendingFeed = const [],
    PlaylistInfo? playlistInfo,
  }) : playlistInfo =
           playlistInfo ??
           const PlaylistInfo(
             id: 'pl1',
             title: 'Test playlist',
             author: 'Channel One',
             videoCount: 2,
             videos: testVideos,
           ) {
    details ??= VideoDetails(
      info: testVideos.first,
      description: 'A video description',
      streams: testStreams,
    );
  }

  T _fail<T>() {
    final e = error;
    if (e != null) throw e;
    throw StateError('unexpected call');
  }

  @override
  Future<List<VideoInfo>> homeFeed() async => error != null ? _fail() : feed;

  @override
  Future<List<VideoInfo>> trending() async =>
      error != null ? _fail() : trendingFeed;

  @override
  Future<SearchResults> search(String query, {SearchFilter? filter}) async {
    searchFilters.add(filter);
    return error != null ? _fail() : searchResults;
  }

  final searchFilters = <SearchFilter?>[];

  Map<String, YouTubeRoute> resolvedUrls = const {};
  @override
  Future<YouTubeRoute?> resolveUrl(String url) async => resolvedUrls[url];

  @override
  Future<List<String>> searchSuggestions(String query) async {
    if (error != null) return _fail();
    final gate = suggestionsGate;
    if (gate != null) {
      suggestionsGate = null;
      return gate.future;
    }
    return suggestions;
  }

  List<String> suggestions = const [];
  Completer<List<String>>? suggestionsGate;

  @override
  Future<VideoDetails> videoDetails(String videoId) async {
    if (error != null) return _fail();
    final gate = detailsGate;
    if (gate != null) return gate.future;
    return details!;
  }

  @override
  Future<List<VideoInfo>> relatedVideos(String videoId) async =>
      error != null ? _fail() : related;

  @override
  Future<CommentsResult> comments(
    String videoId, {
    String? continuation,
    CommentSort? sort,
  }) async {
    commentSortCalls.add(sort);
    if (error != null) return _fail();
    if (sort != null && failingSorts.contains(sort)) {
      throw StateError('sort down');
    }
    if (continuation != null && failingCommentPages.contains(continuation)) {
      throw StateError('replies down');
    }
    return continuation == null
        ? commentsResult
        : commentPages[continuation] ?? const CommentsResult();
  }

  @override
  Future<ChannelInfo> channel(String channelId) async =>
      error != null ? _fail() : channelInfo;

  @override
  Future<List<VideoInfo>> channelVideos(String channelId) async =>
      error != null ? _fail() : uploads;

  Map<String, String> channelResolutions = const {};

  @override
  Future<String?> resolveChannel(String url) async => channelResolutions[url];

  PlaylistInfo playlistInfo;

  @override
  Future<PlaylistInfo> playlist(String playlistId) async =>
      error != null ? _fail() : playlistInfo;

  List<CaptionCue> captionCues = const [];
  Object? captionsError;
  final captionRequests = <CaptionTrack>[];

  @override
  Future<List<CaptionCue>> captions(CaptionTrack track) async {
    captionRequests.add(track);
    final e = captionsError;
    if (e != null) throw e;
    return captionCues;
  }
}

class FakePlayerController implements PlayerController {
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _buffering = StreamController<bool>.broadcast();
  final _rateChanges = StreamController<double>.broadcast();
  final _volumeChanges = StreamController<double>.broadcast();
  final _mutedChanges = StreamController<bool>.broadcast();
  final _completed = StreamController<bool>.broadcast();
  final _buffered = StreamController<Duration>.broadcast();

  @override
  Duration position = Duration.zero;
  @override
  Duration duration = const Duration(minutes: 3);
  @override
  Duration buffered = Duration.zero;
  @override
  bool playing = false;
  @override
  bool buffering = false;
  @override
  double rate = 1.0;
  @override
  double volume = 1.0;
  @override
  bool muted = false;
  @override
  final ValueNotifier<BoxFit> videoFit = ValueNotifier(BoxFit.contain);
  bool disposed = false;
  Completer<void>? openGate;
  Object? openError;
  final opened = <String>[];
  Duration? lastSeek;
  final seeks = <Duration>[];
  bool paused = false;
  bool played = false;
  bool videoEnabled = true;

  void emitPosition(Duration d) {
    position = d;
    _position.add(d);
  }

  void emitDuration(Duration d) => _duration.add(d);
  void emitPlaying(bool v) => _playing.add(v);
  void emitBuffering(bool v) => _buffering.add(v);
  void emitBuffered(Duration d) => _buffered.add(d);
  void emitCompleted() => _completed.add(true);

  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Stream<Duration> get durationStream => _duration.stream;
  @override
  Stream<Duration> get bufferedStream => _buffered.stream;
  @override
  Stream<bool> get playingStream => _playing.stream;
  @override
  Stream<bool> get bufferingStream => _buffering.stream;
  @override
  Stream<double> get rateStream => _rateChanges.stream;
  @override
  Stream<double> get volumeStream => _volumeChanges.stream;
  @override
  Stream<bool> get mutedStream => _mutedChanges.stream;
  @override
  Stream<bool> get completedStream => _completed.stream;

  @override
  Future<void> open(String url, {String? audioUrl}) async {
    final error = openError;
    if (error != null) throw error;
    opened.add(audioUrl == null ? url : '$url+$audioUrl');
    playing = true;
    position = Duration.zero;
    rate = 1.0;
    await openGate?.future;
  }

  @override
  Future<void> play() async {
    played = true;
    playing = true;
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    paused = true;
    playing = false;
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
    seeks.add(position);
  }

  @override
  Future<void> setRate(double rate) async {
    this.rate = rate;
    _rateChanges.add(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    _volumeChanges.add(volume);
  }

  @override
  Future<void> setMuted(bool muted) async {
    this.muted = muted;
    _mutedChanges.add(muted);
  }

  @override
  Future<void> setVideoEnabled(bool enabled) async {
    videoEnabled = enabled;
  }

  @override
  Widget buildView(BuildContext context) =>
      Container(color: const Color(0xFF123456), child: const SizedBox.expand());

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeRydClient extends RydClient {
  FakeRydClient({this.count});

  final int? count;
  int calls = 0;
  Object? failure;

  @override
  Future<int?> dislikes(String videoId) async {
    calls++;
    final e = failure;
    if (e != null) throw e;
    return count;
  }
}

class FakeShareActions extends ShareActions {
  final List<String> shared = [];

  @override
  Future<void> share(String text) async => shared.add(text);
}

class FakeOrientationActions extends OrientationActions {
  int landscapeCalls = 0;
  int restoreCalls = 0;

  @override
  Future<void> landscape() async => landscapeCalls++;

  @override
  Future<void> restore() async => restoreCalls++;
}

class FakeMcpServer implements McpServer {
  @override
  bool running = false;
  Object? startError;

  @override
  String? get url => running ? 'http://127.0.0.1:8642/mcp' : null;

  @override
  Future<void> start() async {
    final error = startError;
    if (error != null) throw error;
    running = true;
  }

  @override
  Future<void> stop() async {
    running = false;
  }
}

class FakeWindowActions implements WindowActions {
  int minimized = 0;
  int maximized = 0;
  int closed = 0;
  int dragged = 0;

  @override
  Future<void> minimize() async => minimized++;
  @override
  Future<void> toggleMaximize() async => maximized++;
  @override
  Future<void> close() async => closed++;
  @override
  Future<void> startDrag() async => dragged++;
}

class FakeVersionChecker extends VersionChecker {
  AppUpdate? result;
  bool fail;

  FakeVersionChecker({this.result, this.fail = false})
    : super(client: MockClient((_) async => http.Response('[]', 200)));

  @override
  Future<AppUpdate> check(String currentVersion) async {
    if (fail) throw const VersionCheckException('nope');
    return result ??
        AppUpdate(
          currentVersion: currentVersion,
          releaseUrl: VersionChecker.releasesUrl,
        );
  }
}

class FakeBrightnessControl implements BrightnessControl {
  double value = 0.8;
  final sets = <double>[];

  @override
  Future<double> getBrightness() async => value;

  @override
  Future<void> setBrightness(double v) async {
    value = v;
    sets.add(v);
  }
}

Future<AppState> testState({
  LinkActions? links,
  SharedPreferences? prefs,
  FakeYouTubeApi? api,
  FakePlayerController? player,
  PlayerController Function()? createPlayer,
  FakeWindowActions? windowActions,
  FakeVersionChecker? versionChecker,
  SettingsStore? settings,
  SubscriptionsStore? subscriptions,
  WatchLaterStore? watchLater,
  PlaylistsStore? playlists,
  HistoryStore? history,
  SearchHistoryStore? searchHistory,
  List<Uri>? launched,
  bool isWeb = false,
  McpServerFactory? createMcpServer,
  Future<PackageInfo> Function()? packageInfo,
  SaveFile? saveFile,
  Future<String?> Function()? openFile,
  SponsorBlockClient? sponsorBlock,
  UploadsWatcher? uploads,
  PipActions? pipActions,
  OrientationActions? orientation,
  MediaControls? mediaControls,
  RydClient? ryd,
  ShareActions? share,
  BrightnessControl? brightness,
  DownloadActions? downloads,
  DownloadsStore? downloadsStore,
  Map<String, Object> initialPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final p = prefs ?? await SharedPreferences.getInstance();
  return AppState(
    prefs: p,
    api: api ?? FakeYouTubeApi(feed: testVideos),
    settings: settings ?? await SettingsStore.load(p),
    subscriptions: subscriptions ?? await SubscriptionsStore.load(p),
    watchLater: watchLater ?? await WatchLaterStore.load(p),
    playlists: playlists ?? await PlaylistsStore.load(p),
    history: history ?? await HistoryStore.load(p),
    searchHistory: searchHistory ?? await SearchHistoryStore.load(p),
    launch: (uri) async {
      launched?.add(uri);
      return true;
    },
    packageInfo:
        packageInfo ??
        () async => PackageInfo(
          appName: 'NewTube',
          packageName: 'gitlab.httpanimations.newtube',
          version: '1.2.3',
          buildNumber: '4',
        ),
    createPlayer: createPlayer ?? () => player ?? FakePlayerController(),
    windowActions: windowActions,
    createMcpServer: createMcpServer,
    saveFile: saveFile,
    openFile: openFile,
    sponsorBlock: sponsorBlock,
    uploads: uploads,
    pipActions: pipActions,
    orientation: orientation,
    ryd: ryd,
    links: links,
    share: share,
    downloads: downloads,
    downloadsStore: downloadsStore,
    mediaControls: mediaControls,
    brightness: brightness,
    versionChecker: versionChecker ?? FakeVersionChecker(),
    isWeb: isWeb,
  );
}

const _pngPixel = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0B,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x62,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient extends Fake implements HttpClient {
  bool _closed = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (_closed) throw StateError('closed');
    return _FakeRequest();
  }

  @override
  void close({bool force = false}) => _closed = true;
}

class _FakeRequest extends Fake implements HttpClientRequest {
  final _response = _FakeResponse();

  @override
  Future<HttpClientResponse> close() async => _response;

  @override
  Future<HttpClientResponse> get done async => _response;
}

class _FakeResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;
  @override
  String get reasonPhrase => 'OK';
  @override
  int get contentLength => _pngPixel.length;
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(Uint8List.fromList(_pngPixel)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

Future<void> pumpPage(
  WidgetTester tester,
  AppState state,
  Widget child, {
  Size? size,
  Locale? locale,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(fontFamily: 'Inter'),
        home: Scaffold(body: child),
      ),
    ),
  );
}

class FakePipActions implements PipActions {
  int enters = 0;
  int exits = 0;
  int updates = 0;
  bool supported = true;
  String? lastUrl;
  String? lastAudioUrl;

  @override
  final ValueNotifier<bool> pipMode = ValueNotifier<bool>(false);

  @override
  Future<bool> enterPip() async {
    enters++;
    return supported;
  }

  @override
  Future<void> exitPip() async {
    exits++;
  }

  @override
  void updatePlayback(
    PlayerController? player, {
    String? url,
    String? audioUrl,
  }) {
    updates++;
    lastUrl = url;
    lastAudioUrl = audioUrl;
  }
}

class FakeMediaControls implements MediaControls {
  int attaches = 0;
  int detaches = 0;
  bool attachThrows = false;
  String? lastTitle;
  String? lastArtist;
  String? lastArtwork;

  @override
  Future<void> attach(
    PlayerController player, {
    required String title,
    String? artist,
    String? artworkUri,
  }) async {
    if (attachThrows) throw StateError('no audio service');
    attaches++;
    lastTitle = title;
    lastArtist = artist;
    lastArtwork = artworkUri;
  }

  @override
  Future<void> detach(PlayerController player) async {
    detaches++;
  }
}

class FakeLinkActions implements LinkActions {
  final linksController = StreamController<Uri>.broadcast();
  Uri? initialLink;

  @override
  Stream<Uri> get links => linksController.stream;

  @override
  Future<Uri?> get initial async => initialLink;
}
