import '../models/video_info.dart';
import '../state/settings_store.dart';

List<VideoInfo> visibleVideos(List<VideoInfo> videos, SettingsStore settings) =>
    settings.hideShorts ? videos.where((v) => !v.isShort).toList() : videos;
