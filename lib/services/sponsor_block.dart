import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'player_controller.dart';

class SponsorSegment {
  final String category;
  final Duration start;
  final Duration end;

  const SponsorSegment({
    required this.category,
    required this.start,
    required this.end,
  });
}

class SponsorBlockException implements Exception {
  final String message;
  const SponsorBlockException(this.message);

  @override
  String toString() => 'SponsorBlockException: $message';
}

class SponsorBlockClient {
  static const _base = 'https://sponsor.ajay.app';

  final http.Client _client;

  SponsorBlockClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<SponsorSegment>> segments(
    String videoId,
    Set<String> categories,
  ) async {
    final response = await _client.get(
      Uri.parse('$_base/api/skipSegments').replace(
        queryParameters: {
          'videoID': videoId,
          'categories': jsonEncode(categories.toList()),
        },
      ),
    );
    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) {
      throw SponsorBlockException(
        'skipSegments failed with ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded)
        if (entry is Map<String, dynamic> && entry['segment'] is List)
          SponsorSegment(
            category: entry['category'] as String? ?? '',
            start: _seconds((entry['segment'] as List).first),
            end: _seconds((entry['segment'] as List).last),
          ),
    ];
  }

  static Duration _seconds(dynamic value) =>
      Duration(milliseconds: ((value as num) * 1000).round());
}

class SegmentSkipper extends ChangeNotifier {
  SegmentSkipper({
    required this.player,
    required List<SponsorSegment> segments,
    this.autoSkip = true,
  }) : _segments = segments {
    _positionSub = player.positionStream.listen(_onPosition);
    _onPosition(player.position);
  }

  final PlayerController player;
  final List<SponsorSegment> _segments;
  final bool autoSkip;
  final _skipped = <SponsorSegment>{};

  StreamSubscription<Duration>? _positionSub;
  SponsorSegment? _active;

  SponsorSegment? get active => _active;

  void _onPosition(Duration position) {
    SponsorSegment? hit;
    for (final segment in _segments) {
      if (position >= segment.start && position < segment.end) {
        hit = segment;
        break;
      }
    }
    if (hit != null && autoSkip) {
      if (_skipped.add(hit)) player.seek(hit.end);
      hit = null;
    }
    if (hit != _active) {
      _active = hit;
      notifyListeners();
    }
  }

  void skip() {
    final segment = _active;
    if (segment == null) return;
    _skipped.add(segment);
    _active = null;
    player.seek(segment.end);
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
