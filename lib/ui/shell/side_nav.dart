import 'package:flutter/material.dart';

typedef SideNavDestination = ({
  IconData icon,
  IconData selectedIcon,
  String label,
});

class SideNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<SideNavDestination> destinations;
  final int footerCount;
  final Widget? header;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final String? toggleLabel;

  const SideNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    this.footerCount = 0,
    this.header,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.toggleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final primaryCount = destinations.length - footerCount;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: collapsed ? 72 : 208,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null)
              LayoutBuilder(
                builder: (context, constraints) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth < 100 ? 8 : 16,
                    14,
                    constraints.maxWidth < 100 ? 8 : 16,
                    8,
                  ),
                  child: header,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  12,
                  header == null ? 16 : 4,
                  12,
                  16,
                ),
                itemCount: primaryCount,
                itemBuilder: (context, index) => _SideNavItem(
                  destination: destinations[index],
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              ),
            ),
            if (footerCount > 0 || onToggleCollapsed != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Column(
                  children: [
                    for (var i = primaryCount; i < destinations.length; i++)
                      _SideNavItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    if (onToggleCollapsed != null)
                      _SideNavItem(
                        destination: (
                          icon: collapsed
                              ? Icons.keyboard_double_arrow_right
                              : Icons.keyboard_double_arrow_left,
                          selectedIcon: collapsed
                              ? Icons.keyboard_double_arrow_right
                              : Icons.keyboard_double_arrow_left,
                          label: toggleLabel ?? '',
                        ),
                        selected: false,
                        onTap: onToggleCollapsed!,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final SideNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;
    final icon = Icon(
      selected ? destination.selectedIcon : destination.icon,
      size: 22,
      color: foreground,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? colors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 100) {
                return Tooltip(
                  message: destination.label,
                  waitDuration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Center(child: icon),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
