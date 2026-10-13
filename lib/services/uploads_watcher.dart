import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import '../models/video_info.dart';
import '../state/settings_store.dart';
import '../state/subscriptions_store.dart';
import '../utils/debug_log.dart';
import 'notifier.dart';

class UploadEntry {
  final String videoId;
  final String title;
  final DateTime published;

  const UploadEntry({
    required this.videoId,
    required this.title,
    required this.published,
  });
}

class UploadsWatcher {
  static const _seenKey = 'upload_seen';

  final SharedPreferences prefs;
  final SubscriptionsStore subscriptions;
  final NotifyCallback notify;
  final http.Client _client;

  Timer? _timer;
  Duration? _interval;
  SettingsStore? _settings;
  Map<String, DateTime> _seen = {};
  bool _checking = false;

  UploadsWatcher({
    required this.prefs,
    required this.subscriptions,
    required this.notify,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    final raw = prefs.getString(_seenKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _seen = {
            for (final entry in decoded.entries)
              entry.key:
                  DateTime.tryParse(entry.value as String? ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
          };
        }
      } catch (_) {}
    }
  }

  bool get running => _timer != null;
  Duration? get interval => _interval;

  void attach(SettingsStore settings) {
    if (_settings == settings) return;
    _settings?.removeListener(_sync);
    _settings = settings;
    settings.addListener(_sync);
    _sync();
  }

  void _sync() {
    final settings = _settings;
    if (settings == null) return;
    if (settings.uploadNotificationsEnabled) {
      start(Duration(minutes: settings.uploadCheckIntervalMinutes));
    } else {
      stop();
    }
  }

  void start(Duration interval) {
    if (_interval == interval && _timer != null) return;
    _interval = interval;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(checkNow()));
    unawaited(checkNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _interval = null;
  }

  void dispose() {
    stop();
    _settings?.removeListener(_sync);
    _settings = null;
    _client.close();
  }

  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      for (final channel in subscriptions.channels) {
        final entry = await _tryLatest(channel);
        if (entry == null) continue;
        final seen = _seen[channel.id];
        if (seen == null) {
          _seen[channel.id] = entry.published;
        } else if (entry.published.isAfter(seen)) {
          _seen[channel.id] = entry.published;
          await notify(channel.name, entry.title);
        }
      }
      await _save();
    } finally {
      _checking = false;
    }
  }

  Future<UploadEntry?> _tryLatest(ChannelInfo channel) => _latestUpload(
    channel.id,
  ).then((entry) => entry, onError: (Object e) => _logFailure(channel, e));

  UploadEntry? _logFailure(ChannelInfo channel, Object error) {
    debugLog('[uploads] ${channel.id}: check failed: $error');
    return null;
  }

  Future<UploadEntry?> _latestUpload(String channelId) async {
    final response = await _client.get(
      Uri.parse(
        'https://www.youtube.com/feeds/videos.xml?channel_id=$channelId',
      ),
    );
    if (response.statusCode != 200) return null;
    final doc = XmlDocument.parse(response.body);
    UploadEntry? newest;
    for (final entry in doc.findAllElements('entry')) {
      final videoId = _childText(entry, 'videoId');
      final title = _childText(entry, 'title');
      final published = DateTime.tryParse(_childText(entry, 'published') ?? '');
      if (videoId == null || title == null || published == null) continue;
      if (newest == null || published.isAfter(newest.published)) {
        newest = UploadEntry(
          videoId: videoId,
          title: title,
          published: published,
        );
      }
    }
    return newest;
  }

  String? _childText(XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      if (child.name.local == localName) return child.innerText;
    }
    return null;
  }

  Future<void> _save() => prefs.setString(
    _seenKey,
    jsonEncode({
      for (final entry in _seen.entries)
        entry.key: entry.value.toIso8601String(),
    }),
  );
}
