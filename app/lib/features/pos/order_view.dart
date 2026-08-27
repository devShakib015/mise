import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/ui_state.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../data/models/menu.dart';
import '../../data/models/service.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';
import 'modifier_sheet.dart';
import 'pos_shell.dart';
import 'ticket_panel.dart';

/// Taking an order: the menu on one side, the running bill on the other.
class OrderView extends ConsumerWidget {
  const OrderView({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final order = ref.watch(orderProvider(orderId));

    return AsyncView<Order?>(
      value: order,
      onRetry: () => ref.invalidate(orderProvider(orderId)),
      data: (o) {
        if (o == null) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'This bill is gone',
            message: 'It was settled or cancelled on another device.',
            action: FilledButton(
              onPressed: () => ref.read(activeOrderIdProvider.notifier).set(null),
              child: const Text('Back to the floor'),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 940;

            return Column(
              children: [
                _OrderHeader(order: o),
                Divider(height: 1, color: p.border),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: _MenuGrid(order: o)),
                            VerticalDivider(width: 1, color: p.border),
                            SizedBox(width: 372, child: TicketPanel(order: o)),
                          ],
                        )
                      : _NarrowLayout(order: o),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OrderHeader extends ConsumerWidget {
  const _OrderHeader({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tables = ref.watch(tablesProvider).value ?? const <DiningTable>[];
    final table = tables.where((t) => t.id == order.tableId).firstOrNull;

    final title = table != null
        ? table.label
        : order.type == OrderType.takeaway
            ? 'Takeaway'
            : order.type.label;

    return Container(
      height: 62,
      color: p.surface,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to the floor',
            onPressed: () => ref.read(activeOrderIdProvider.notifier).set(null),
            icon: Icon(Icons.arrow_back_rounded, size: 20, color: p.textPrimary),
          ),
          const SizedBox(width: Space.xxs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: AppType.subtitle.copyWith(color: p.textPrimary)),
              Text(
                [
                  'Bill #${order.number}',
                  if (order.guestCount > 0)
                    '${order.guestCount} ${order.guestCount == 1 ? 'guest' : 'guests'}',
                  order.status.label,
                ].join(' · '),
                style: AppType.caption.copyWith(color: p.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Menu on top, a bar showing the bill total that opens the full ticket.
/// This is the handheld shape — a waiter taking orders at the table.
class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';
    final lines = ref.watch(orderLinesProvider(order.id)).value ?? const <OrderLine>[];
    final count = lines.where((l) => !l.isVoid).fold(0, (sum, l) => sum + l.qty);

    return Column(
      children: [
        Expanded(child: _MenuGrid(order: order)),
        Divider(height: 1, color: p.border),
        Container(
          color: p.surface,
          padding: const EdgeInsets.all(Space.sm),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: Hit.button,
              child: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: const EdgeInsets.all(Space.md),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: TicketPanel(order: order, onDone: () {
                        Navigator.of(context).pop();
                      }),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(count == 1 ? 'View bill · 1 item' : 'View bill · $count items'),
                    Text('$symbol${order.total.toStringAsFixed(2)}',
                        style: AppType.money.copyWith(color: p.onBrand)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final _posCategoryProvider = uiValue<String?>(null);

class _MenuGrid extends ConsumerWidget {
  const _MenuGrid({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final items = ref.watch(menuItemsProvider);
    final selected = ref.watch(_posCategoryProvider);

    // Watched, not read: these decide whether tapping a tile asks a question,
    // and a provider nothing watches never loads.
    final links = ref.watch(itemModifierLinksProvider).value ?? const {};
    ref.watch(modifierGroupsProvider);
    ref.watch(modifiersProvider);

    final visibleCategories = categories.where((c) => c.active).toList();

    return AsyncView<List<MenuItem>>(
      value: items,
      onRetry: () => ref.invalidate(menuItemsProvider),
      data: (all) {
        final categoryId = selected ??
            (visibleCategories.isNotEmpty ? visibleCategories.first.id : null);

        final shown = all
            .where((i) => i.active && i.categoryId == categoryId)
            .toList();

        if (visibleCategories.isEmpty) {
          return const EmptyState(
            icon: Icons.restaurant_menu_rounded,
            title: 'The menu is empty',
            message: 'A manager needs to add categories and items first.',
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.md, vertical: Space.xs),
                children: [
                  for (final c in visibleCategories)
                    _CategoryTab(
                      category: c,
                      selected: c.id == categoryId,
                      onTap: () =>
                          ref.read(_posCategoryProvider.notifier).set(c.id),
                    ),
                ],
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Nothing in here',
                      message: 'This category has no items on the menu yet.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          Space.md, 0, Space.md, Space.xl),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 190,
                        mainAxisExtent: 116,
                        crossAxisSpacing: Space.xs,
                        mainAxisSpacing: Space.xs,
                      ),
                      itemCount: shown.length,
                      itemBuilder: (context, i) => _ItemTile(
                        item: shown[i],
                        hasOptions: (links[shown[i].id] ?? const []).isNotEmpty,
                        onTap: () => _add(context, ref, shown[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref, MenuItem item) async {
    final repo = ref.read(serviceRepositoryProvider);
    final links = ref.read(itemModifierLinksProvider).value ?? const {};
    final groupIds = links[item.id] ?? const <String>[];

    var qty = 1;
    var modifiers = const <SelectedModifier>[];
    var note = '';

    // Only interrupt with a sheet when the item actually asks something.
    if (groupIds.isNotEmpty) {
      final allGroups =
          ref.read(modifierGroupsProvider).value ?? const <ModifierGroup>[];
      final groups = [
        for (final id in groupIds)
          ...allGroups.where((g) => g.id == id),
      ];

      if (groups.isNotEmpty) {
        final choice = await showLineChoiceSheet(
          context: context,
          item: item,
          groups: groups,
        );
        if (choice == null) return;
        qty = choice.qty;
        modifiers = choice.modifiers;
        note = choice.note;
      }
    }

    try {
      await repo.addLine(
        orderId: order.id,
        item: item,
        qty: qty,
        modifiers: modifiers,
        note: note,
      );
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add that: $err')));
      }
    }
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(right: Space.xs),
      child: Material(
        color: selected ? p.brand : p.surfaceSunken,
        borderRadius: Radii.medium,
        child: InkWell(
          borderRadius: Radii.medium,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: Radii.medium,
              border: Border.all(color: selected ? p.brand : p.border),
            ),
            child: Text(
              category.name,
              style: AppType.bodyStrong.copyWith(
                color: selected ? p.onBrand : p.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({
    required this.item,
    required this.onTap,
    this.hasOptions = false,
  });

  final MenuItem item;
  final VoidCallback onTap;

  /// Marks tiles that will ask a question before landing on the bill.
  final bool hasOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';
    final out = !item.available;

    return Material(
      color: out ? p.surfaceSunken : p.surface,
      borderRadius: Radii.large,
      child: InkWell(
        borderRadius: Radii.large,
        // A sold-out item is not tappable at all — far better than letting it
        // onto a bill and finding out at the pass.
        onTap: out ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            borderRadius: Radii.large,
            border: Border.all(color: out ? p.border : p.borderStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.bodyStrong.copyWith(
                          color: out ? p.textTertiary : p.textPrimary,
                        ),
                      ),
                    ),
                    if (hasOptions && !out)
                      Padding(
                        padding: const EdgeInsets.only(left: Space.xxs),
                        child: Icon(Icons.tune_rounded,
                            size: 13, color: p.textTertiary),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xxs),
              Row(
                children: [
                  Text(
                    '$symbol${item.price.toStringAsFixed(2)}',
                    style: AppType.money.copyWith(
                      color: out ? p.textTertiary : p.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (out)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Space.xs, vertical: 1),
                      decoration: BoxDecoration(
                        color: p.dangerSubtle,
                        borderRadius: Radii.pill,
                        border: Border.all(color: p.danger.withValues(alpha: 0.35)),
                      ),
                      child: Text('86',
                          style: AppType.caption.copyWith(color: p.danger)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
