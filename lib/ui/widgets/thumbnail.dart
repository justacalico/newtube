import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class VideoThumbnail extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;

  const VideoThumbnail({
    super.key,
    this.url,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.placeholderIcon = Icons.play_circle_outline,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(placeholderIcon, size: 32),
    );

    final scope =
        context.getElementForInheritedWidgetOfExactType<AppScope>()?.widget
            as AppScope?;
    final settings = scope?.notifier?.settings;

    Widget buildFor(bool saver) {
      if (url == null || url!.isEmpty || saver) {
        return ClipRRect(borderRadius: borderRadius, child: placeholder);
      }
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          url!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : placeholder,
        ),
      );
    }

    if (settings == null) return buildFor(false);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => buildFor(settings.dataSaver),
    );
  }
}
