import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/ui_state.dart';
import 'floor/tables_page.dart';
import 'reports/reports_page.dart';
import 'menu/categories_page.dart';
import 'people/staff_page.dart';
import 'menu/items_page.dart';
import 'menu/modifiers_page.dart';
import 'settings/settings_page.dart';

enum ManagerSection {
  items('Items', Icons.restaurant_menu_rounded, 'Menu'),
  categories('Categories', Icons.category_outlined, 'Menu'),
  modifiers('Modifiers', Icons.tune_rounded, 'Menu'),
  tables('Tables', Icons.table_restaurant_outlined, 'Floor'),
  staff('Staff', Icons.badge_outlined, 'Floor'),
  reports('Reports', Icons.insights_rounded, 'Business'),
  settings('Settings', Icons.settings_outlined, 'Business');

  const ManagerSection(this.label, this.icon, this.group);

  final String label;
  final IconData icon;
  final String group;

}

final managerSectionProvider = uiValue<ManagerSection>(ManagerSection.items);

class ManagerShell extends ConsumerWidget {
  const ManagerShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final section = ref.watch(managerSectionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Below tablet width the labels go and the sidebar becomes a rail.
        final compact = constraints.maxWidth < Breakpoints.tablet;

        return Row(
          // Without stretch, Row centres its children vertically and the
          // sidebar shrinks to its content instead of filling the height.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              current: section,
              compact: compact,
              onSelect: (s) =>
                  ref.read(managerSectionProvider.notifier).set(s),
            ),
            VerticalDivider(width: 1, color: p.border),
            Expanded(
              child: switch (section) {
                ManagerSection.items => const ItemsPage(),
                ManagerSection.categories => const CategoriesPage(),
                ManagerSection.modifiers => const ModifiersPage(),
                ManagerSection.tables => const TablesPage(),
                ManagerSection.staff => const StaffPage(),
                ManagerSection.reports => const ReportsPage(),
                ManagerSection.settings => const SettingsPage(),
              },
            ),
          ],
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.current,
    required this.compact,
    required this.onSelect,
  });

  final ManagerSection current;
  final bool compact;
  final ValueChanged<ManagerSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Group the destinations while keeping their declared order.
    final groups = <String, List<ManagerSection>>{};
    for (final s in ManagerSection.values) {
      groups.putIfAbsent(s.group, () => []).add(s);
    }

    return Container(
      width: compact ? 68 : 214,
      color: p.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in groups.entries) ...[
              if (!compact)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Space.md, Space.md, Space.md, Space.xs),
                  child: Text(entry.key.toUpperCase(),
                      style: AppType.overline.copyWith(color: p.textTertiary)),
                )
              else
                const SizedBox(height: Space.sm),
              for (final s in entry.value)
                _NavTile(
                  section: s,
                  selected: s == current,
                  compact: compact,
                  onTap: () => onSelect(s),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.section,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final ManagerSection section;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.brand : p.textSecondary;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 1),
      child: Material(
        color: selected ? p.brandSubtle : Colors.transparent,
        borderRadius: Radii.medium,
        child: InkWell(
          borderRadius: Radii.medium,
          onTap: onTap,
          child: Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : Space.sm),
            child: Row(
              mainAxisAlignment:
                  compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(section.icon, size: 19, color: fg),
                if (!compact) ...[
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      section.label,
                      style: AppType.body.copyWith(
                        color: selected ? p.brand : p.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return compact ? Tooltip(message: section.label, child: tile) : tile;
  }
}
