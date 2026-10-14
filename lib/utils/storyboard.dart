import 'dart:ui';

import '../models/video_info.dart';

class StoryboardTile {
  final String url;
  final Rect sourceRect;

  const StoryboardTile(this.url, this.sourceRect);
}

List<Storyboard> parseStoryboardSpec(String spec) {
  final parts = spec.split('|');
  if (parts.length < 2) return const [];
  final base = parts[0];
  final boards = <Storyboard>[];
  for (var i = 1; i < parts.length; i++) {
    final data = parts[i].split('#');
    if (data.length < 8) continue;
    final width = int.tryParse(data[0]) ?? 0;
    final height = int.tryParse(data[1]) ?? 0;
    final count = int.tryParse(data[2]) ?? 0;
    final cols = int.tryParse(data[3]) ?? 0;
    final rows = int.tryParse(data[4]) ?? 0;
    final interval = int.tryParse(data[5]) ?? 0;
    if (width <= 0 || height <= 0 || count <= 0 || cols <= 0 || rows <= 0) {
      continue;
    }
    boards.add(
      Storyboard(
        urlTemplate: base
            .replaceAll(r'$L', '${i - 1}')
            .replaceAll(r'$N', data[6]),
        sigh: data[7],
        tileWidth: width,
        tileHeight: height,
        tileCount: count,
        cols: cols,
        rows: rows,
        interval: Duration(milliseconds: interval),
      ),
    );
  }
  return boards;
}

Storyboard? bestStoryboard(List<Storyboard> boards) {
  if (boards.isEmpty) return null;
  var best = boards.first;
  for (final board in boards.skip(1)) {
    if (board.tileWidth * board.tileHeight > best.tileWidth * best.tileHeight) {
      best = board;
    }
  }
  return best;
}

StoryboardTile? storyboardTileAt(Storyboard board, Duration position) {
  if (board.interval <= Duration.zero) return null;
  var index = position.inMilliseconds ~/ board.interval.inMilliseconds;
  if (index < 0) index = 0;
  if (index >= board.tileCount) index = board.tileCount - 1;
  final tile = index % board.tilesPerBoard;
  return StoryboardTile(
    board.boardUrl(index ~/ board.tilesPerBoard),
    Rect.fromLTWH(
      (tile % board.cols) * board.tileWidth.toDouble(),
      (tile ~/ board.cols) * board.tileHeight.toDouble(),
      board.tileWidth.toDouble(),
      board.tileHeight.toDouble(),
    ),
  );
}
