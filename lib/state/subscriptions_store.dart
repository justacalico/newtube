import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_info.dart';

class SubscriptionsStore extends ChangeNotifier {
  static const _key = 'subscriptions';

  static const _groupsKey = 'subscription_groups';

  static const _mutedKey = 'subscription_muted';

  final Map<String, ChannelInfo> _channels;
  final Map<String, String> _groups;
  final Set<String> _muted;

  SubscriptionsStore([
    Map<String, ChannelInfo>? channels,
    Map<String, String>? groups,
    Set<String>? muted,
  ]) : _channels = Map.of(channels ?? const {}),
       _groups = Map.of(groups ?? const {}),
       _muted = Set.of(muted ?? const {});

  static Future<SubscriptionsStore> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    final groups = <String, String>{};
    final muted = (prefs.getStringList(_mutedKey) ?? const []).toSet();
    final rawGroups = prefs.getString(_groupsKey);
    if (rawGroups != null) {
      try {
        final decoded = jsonDecode(rawGroups);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (k is String && v is String) groups[k] = v;
          });
        }
      } catch (_) {}
    }
    if (raw == null) return SubscriptionsStore(null, groups, muted);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return SubscriptionsStore(null, groups, muted);
      }
      return SubscriptionsStore(
        {
          for (final e in decoded.entries)
            if (e.value is Map<String, dynamic>)
              e.key: _decodeChannel(e.value as Map<String, dynamic>),
        },
        groups,
        muted,
      );
    } catch (_) {
      return SubscriptionsStore(null, groups, muted);
    }
  }

  static ChannelInfo _decodeChannel(Map<String, dynamic> json) => ChannelInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    thumbnailUrl: json['thumbnail'] as String?,
    subscribers: json['subscribers'] as int?,
  );

  Future<void> reload(SharedPreferences prefs) async {
    final fresh = await SubscriptionsStore.load(prefs);
    _channels
      ..clear()
      ..addAll(fresh._channels);
    _groups
      ..clear()
      ..addAll(fresh._groups);
    _muted
      ..clear()
      ..addAll(fresh._muted);
    notifyListeners();
  }

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

  bool isMuted(String channelId) => _muted.contains(channelId);

  Future<void> setMuted(
    String channelId,
    bool muted,
    SharedPreferences prefs,
  ) async {
    if (muted) {
      _muted.add(channelId);
    } else {
      _muted.remove(channelId);
    }
    await prefs.setStringList(_mutedKey, _muted.toList());
    notifyListeners();
  }

  List<String> get groups => _groups.values.toSet().toList();

  String? groupOf(String channelId) => _groups[channelId];

  List<ChannelInfo> channelsInGroup(String? group) => [
    for (final c in _channels.values)
      if (group == null ? true : _groups[c.id] == group) c,
  ];

  Future<void> setGroup(
    String channelId,
    String? group,
    SharedPreferences prefs,
  ) async {
    if (group == null || group.isEmpty) {
      _groups.remove(channelId);
    } else {
      _groups[channelId] = group;
    }
    await prefs.setString(_groupsKey, jsonEncode(_groups));
    notifyListeners();
  }

  Future<void> renameGroup(
    String oldName,
    String newName,
    SharedPreferences prefs,
  ) async {
    if (newName.isEmpty || oldName == newName) return;
    for (final e in _groups.entries.toList()) {
      if (e.value == oldName) _groups[e.key] = newName;
    }
    await prefs.setString(_groupsKey, jsonEncode(_groups));
    notifyListeners();
  }

  Future<void> deleteGroup(String group, SharedPreferences prefs) async {
    _groups.removeWhere((_, g) => g == group);
    await prefs.setString(_groupsKey, jsonEncode(_groups));
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
