import 'dart:convert';

enum SearchSort { relevance, date, views, rating }

enum UploadDate { any, hour, today, week, month, year }

enum VideoDuration { any, short, medium, long }

enum SearchType { all, video, channel, playlist, live }

class SearchFilter {
  final SearchSort sort;
  final UploadDate uploadDate;
  final VideoDuration duration;
  final SearchType type;

  const SearchFilter({
    this.sort = SearchSort.relevance,
    this.uploadDate = UploadDate.any,
    this.duration = VideoDuration.any,
    this.type = SearchType.all,
  });

  bool get isEmpty =>
      sort == SearchSort.relevance &&
      uploadDate == UploadDate.any &&
      duration == VideoDuration.any &&
      type == SearchType.all;

  SearchFilter copyWith({
    SearchSort? sort,
    UploadDate? uploadDate,
    VideoDuration? duration,
    SearchType? type,
  }) => SearchFilter(
    sort: sort ?? this.sort,
    uploadDate: uploadDate ?? this.uploadDate,
    duration: duration ?? this.duration,
    type: type ?? this.type,
  );

  static const _sortCodes = {
    SearchSort.rating: 1,
    SearchSort.date: 2,
    SearchSort.views: 3,
  };

  static const _typeCodes = {
    SearchType.video: 1,
    SearchType.channel: 2,
    SearchType.playlist: 3,
    SearchType.live: 5,
  };

  static const _durationCodes = {
    VideoDuration.short: 1,
    VideoDuration.medium: 2,
    VideoDuration.long: 3,
  };

  String? toParams() {
    if (isEmpty) return null;
    final out = <int>[];
    final sortCode = _sortCodes[sort];
    if (sortCode != null) {
      out.addAll([0x08, sortCode]);
    }
    final group = <int>[];
    final uploadCode = uploadDate.index;
    if (uploadCode > 0) {
      group.addAll([0x08, uploadCode]);
    }
    final typeCode = _typeCodes[type];
    if (typeCode != null) {
      group.addAll([0x10, typeCode]);
    }
    final durationCode = _durationCodes[duration];
    if (durationCode != null) {
      group.addAll([0x18, durationCode]);
    }
    if (group.isNotEmpty) {
      out.addAll([0x12, group.length, ...group]);
    }
    return base64.encode(out);
  }

  @override
  bool operator ==(Object other) =>
      other is SearchFilter &&
      other.sort == sort &&
      other.uploadDate == uploadDate &&
      other.duration == duration &&
      other.type == type;

  @override
  int get hashCode => Object.hash(sort, uploadDate, duration, type);
}
