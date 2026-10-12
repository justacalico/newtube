import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';

class SubscriptionsStore extends ChangeNotifier {
  static const _key = 'subscriptions';

  final Map<String, ChannelInfo> _channels;

  SubscriptionsStore([Map<String, ChannelInfo>? channels])
    : _channels = Map.of(channels ?? const {});

  static Future<SubscriptionsStore> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return SubscriptionsStore();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return SubscriptionsStore();
      return SubscriptionsStore({
        for (final e in decoded.entries)
          if (e.value is Map<String, dynamic>)
            e.key: _decodeChannel(e.value as Map<String, dynamic>),
      });
    } catch (_) {
      return SubscriptionsStore();
    }
  }

  static ChannelInfo _decodeChannel(Map<String, dynamic> json) => ChannelInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    thumbnailUrl: json['thumbnail'] as String?,
    subscribers: json['subscribers'] as int?,
  );

  List<ChannelInfo> get channels => _channels.values.toList();

  bool isSubscribed(String channelId) => _channels.containsKey(channelId);

  Future<void> subscribe(ChannelInfo channel, SharedPreferences prefs) async {
    _channels[channel.id] = channel;
    await _save(prefs);
    notifyListeners();
  }

  Future<void> unsubscribe(String channelId, SharedPreferences prefs) async {
    _channels.remove(channelId);
    await _save(prefs);
    notifyListeners();
  }

  Future<void> _save(SharedPreferences prefs) => prefs.setString(
    _key,
    jsonEncode({
      for (final e in _channels.entries)
        e.key: {
          'id': e.value.id,
          'name': e.value.name,
          'thumbnail': e.value.thumbnailUrl,
          'subscribers': e.value.subscribers,
        },
    }),
  );
}
