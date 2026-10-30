import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/window_actions.dart';

bool get isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

class AppTitleBar extends StatelessWidget {
  final String title;
  final WindowActions? windowActions;
  final bool showControls;

  const AppTitleBar({
    super.key,
    required this.title,
    this.windowActions,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          if (showControls) ...[
            const SizedBox(width: 8),
            TrafficLights(actions: windowActions),
          ],
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => windowActions?.startDrag(),
              onDoubleTap: () => windowActions?.toggleMaximize(),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
          if (showControls) const SizedBox(width: 84),
        ],
      ),
    );
  }
}

class TrafficLights extends StatefulWidget {
  final WindowActions? actions;
  final Axis direction;

  const TrafficLights({
    super.key,
    this.actions,
    this.direction = Axis.horizontal,
  });

  @override
  State<TrafficLights> createState() => _TrafficLightsState();
}

class _TrafficLightsState extends State<TrafficLights> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Flex(
            direction: widget.direction,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Light(
                key: const Key('titlebar.close'),
                color: const Color(0xFFFF5F57),
                glyph: Icons.close,
                tooltip: l10n.close,
                showGlyph: _hovered,
                onTap: widget.actions?.close,
              ),
              const SizedBox.square(dimension: 8),
              _Light(
                key: const Key('titlebar.minimize'),
                color: const Color(0xFFFEBC2E),
                glyph: Icons.remove,
                tooltip: l10n.minimize,
                showGlyph: _hovered,
                onTap: widget.actions?.minimize,
              ),
              const SizedBox.square(dimension: 8),
              _Light(
                key: const Key('titlebar.maximize'),
                color: const Color(0xFF28C840),
                glyph: Icons.add,
                tooltip: l10n.maximize,
                showGlyph: _hovered,
                onTap: widget.actions?.toggleMaximize,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Light extends StatelessWidget {
  final Color color;
  final IconData glyph;
  final String tooltip;
  final bool showGlyph;
  final Future<void> Function()? onTap;

  const _Light({
    super.key,
    required this.color,
    required this.glyph,
    required this.tooltip,
    required this.showGlyph,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap == null ? null : () => onTap!(),
          child: SizedBox(
            width: 20,
            height: 20,
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: showGlyph
                    ? Icon(
                        glyph,
                        size: 9,
                        color: Colors.black.withValues(alpha: 0.6),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
