import '../models/video_info.dart';
import '../state/app_state.dart';
import '../state/settings_store.dart';

List<VideoInfo> visibleVideos(
  List<VideoInfo> videos,
  SettingsStore settings, [
  AppState? state,
]) {
  var out = settings.hideShorts
      ? videos.where((v) => !v.isShort).toList()
      : videos;
  if (settings.hideWatched && state != null) {
    out = out.where((v) => !state.history.contains(v.id)).toList();
  }
  return out;
}
