import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';

void main() {
  test('withContinuation appends and carries token', () {
    const info = PlaylistInfo(
      id: 'PL1',
      title: 'T',
      videoCount: 150,
      videos: [VideoInfo(id: 'a', title: 'a', author: '', channelId: '')],
      continuation: 'tok1',
    );
    final next = info.withContinuation(const [
      VideoInfo(id: 'b', title: 'b', author: '', channelId: ''),
    ], 'tok2');
    expect(next.videos.length, 2);
    expect(next.continuation, 'tok2');
    expect(next.videoCount, 150);
  });
}
