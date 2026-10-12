import 'package:flutter/material.dart';

class VideoThumbnail extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const VideoThumbnail({
    super.key,
    this.url,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.play_circle_outline, size: 32),
    );

    if (url == null || url!.isEmpty) {
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
}
