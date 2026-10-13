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

  const SideNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    this.footerCount = 0,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final primaryCount = destinations.length - footerCount;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: 208,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: header,
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
            if (footerCount > 0)
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? colors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 22,
                  color: foreground,
                ),
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
          ),
        ),
      ),
    );
  }
}
