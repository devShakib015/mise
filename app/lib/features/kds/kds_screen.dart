import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';

/// One ticket on the pass: the bill it belongs to and what is still outstanding.
class _Ticket {
  const _Ticket({required this.order, required this.lines, required this.table});

  final Order order;
  final List<OrderLine> lines;
  final DiningTable? table;

  /// The kitchen clock starts when the ticket was fired, not when the bill was
  /// opened — a table can sit with drinks for an hour before ordering food.
  DateTime get firedAt {
    DateTime? earliest;
    for (final l in lines) {
      final at = l.sentAt;
      if (at == null) continue;
      if (earliest == null || at.isBefore(earliest)) earliest = at;
    }
    return earliest ?? order.created;
  }

  /// Longest prep time on the ticket — the whole thing is only as fast as its
  /// slowest dish.
  bool get allReady => lines.every((l) => l.status == OrderItemStatus.ready);

  String get where => table?.label ?? order.type.label;
}

class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final lines = ref.watch(kitchenLinesProvider);
    final orders = ref.watch(liveOrdersProvider).value ?? const <Order>[];
    final tables = ref.watch(tablesProvider).value ?? const <DiningTable>[];

    // Rebuild every second so the timers count up.
    ref.watch(clockProvider);

    return AsyncView<List<OrderLine>>(
      value: lines,
      onRetry: () => ref.invalidate(kitchenLinesProvider),
      data: (all) {
        final byOrder = <String, List<OrderLine>>{};
        for (final l in all) {
          byOrder.putIfAbsent(l.orderId, () => []).add(l);
        }

        final tickets = <_Ticket>[];
        for (final entry in byOrder.entries) {
          final order = orders.where((o) => o.id == entry.key).firstOrNull;
          if (order == null) continue; // settled or cancelled elsewhere
          tickets.add(_Ticket(
            order: order,
            lines: entry.value,
            table: tables.where((t) => t.id == order.tableId).firstOrNull,
          ));
        }

        // Oldest first: the kitchen works the front of the rail.
        tickets.sort((a, b) => a.firedAt.compareTo(b.firedAt));

        if (tickets.isEmpty) {
          return const EmptyState(
            icon: Icons.soup_kitchen_outlined,
            title: 'Nothing on the pass',
            message: 'Tickets appear here the moment the till sends them.',
          );
        }

        return Column(
          children: [
            _KdsHeader(count: tickets.length),
            Divider(height: 1, color: p.border),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(Space.sm),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisExtent: 400,
                  crossAxisSpacing: Space.sm,
                  mainAxisSpacing: Space.sm,
                ),
                itemCount: tickets.length,
                itemBuilder: (context, i) => _TicketCard(ticket: tickets[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KdsHeader extends ConsumerWidget {
  const _KdsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    return Container(
      height: 52,
      color: p.surface,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Row(
        children: [
          Text('On the pass',
              style: AppType.subtitle.copyWith(color: p.textPrimary)),
          const SizedBox(width: Space.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
            decoration: BoxDecoration(
              color: p.brandSubtle,
              borderRadius: Radii.pill,
            ),
            child: Text('$count',
                style: AppType.label.copyWith(color: p.brand)),
          ),
          const Spacer(),
          Text('$hh:$mm',
              style: AppType.kdsTimer.copyWith(color: p.textSecondary)),
        ],
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  const _TicketCard({required this.ticket});

  final _Ticket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final waiting = now.difference(ticket.firedAt);

    // Ageing runs on the border and the timer only. Item status uses chips, so
    // the two channels can never be confused for one another.
    final age = p.ageing(waiting);
    final late = waiting.inMinutes >= 10;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.large,
        border: Border.all(color: age, width: late ? 2.5 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: late ? p.statusLate.withValues(alpha: 0.14) : p.surfaceSunken,
            padding: const EdgeInsets.symmetric(
                horizontal: Space.sm, vertical: Space.xs),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.where,
                          style: AppType.kdsTicket.copyWith(color: p.textPrimary)),
                      Text(
                        '#${ticket.order.number}'
                        '${ticket.order.guestCount > 0 ? ' · ${ticket.order.guestCount} covers' : ''}',
                        style: AppType.caption.copyWith(color: p.textTertiary),
                      ),
                    ],
                  ),
                ),
                Text(
                  _clock(waiting),
                  style: AppType.kdsTimer.copyWith(
                    color: late ? p.statusLate : p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _TicketBody(ticket: ticket)),
          Padding(
            padding: const EdgeInsets.all(Space.xs),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ticket.allReady ? p.success : p.brand,
                ),
                onPressed: () => _bump(context, ref),
                child: Text(
                  ticket.allReady ? 'Clear from the pass' : 'All ready',
                  style: AppType.bodyStrong.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bump(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(serviceRepositoryProvider);
    // First press plates the whole ticket; a second one hands it to the floor,
    // which takes it off this screen.
    final next = ticket.allReady ? OrderItemStatus.served : OrderItemStatus.ready;

    try {
      await repo.setTicketStatus(ticket.order.id, next);
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update: $err')));
      }
    }
  }
}

/// A ticket's items, grouped by course when it spans more than one so the
/// pass can see what to plate together.
class _TicketBody extends StatelessWidget {
  const _TicketBody({required this.ticket});

  final _Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final courses = ticket.lines.map((l) => l.course).toSet().toList()..sort();

    if (courses.length < 2) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: Space.xxs),
        itemCount: ticket.lines.length,
        itemBuilder: (context, i) => _TicketLine(line: ticket.lines[i]),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      children: [
        for (final c in courses) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.sm, Space.xs, Space.sm, 2),
            child: Text(Course.label(c).toUpperCase(),
                style: AppType.overline.copyWith(color: p.textTertiary)),
          ),
          for (final l in ticket.lines.where((l) => l.course == c))
            _TicketLine(line: l),
        ],
      ],
    );
  }
}

class _TicketLine extends ConsumerWidget {
  const _TicketLine({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    final (dot, label) = switch (line.status) {
      OrderItemStatus.preparing => (p.statusPreparing, 'Cooking'),
      OrderItemStatus.ready => (p.statusReady, 'Ready'),
      _ => (p.statusQueued, null),
    };

    return InkWell(
      onTap: () => _cycle(ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.sm, vertical: Space.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              alignment: Alignment.centerLeft,
              child: Text('${line.qty}×',
                  style: AppType.kdsItem.copyWith(color: p.textSecondary)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.name,
                    style: AppType.kdsItem.copyWith(
                      color: line.status == OrderItemStatus.ready
                          ? p.textTertiary
                          : p.textPrimary,
                      decoration: line.status == OrderItemStatus.ready
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (line.modifiers.isNotEmpty)
                    Text(
                      line.modifiers.map((m) => m.name).join(', '),
                      style: AppType.small.copyWith(color: p.textSecondary),
                    ),
                  // The note is the thing that ruins a dish if it is missed, so
                  // it gets the loudest treatment on the card.
                  if (line.note.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Space.xs, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.warningSubtle,
                        borderRadius: Radii.small,
                        border: Border.all(
                            color: p.warning.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        line.note,
                        style: AppType.small.copyWith(
                          color: p.isDark ? p.warning : p.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (label != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(label,
                          style: AppType.caption.copyWith(color: dot)),
                    ),
                ],
              ),
            ),
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 6, left: Space.xs),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  /// Tapping a line walks it forward: queued → cooking → ready → back to queued.
  Future<void> _cycle(WidgetRef ref) async {
    final next = switch (line.status) {
      OrderItemStatus.queued => OrderItemStatus.preparing,
      OrderItemStatus.preparing => OrderItemStatus.ready,
      _ => OrderItemStatus.queued,
    };
    await ref.read(serviceRepositoryProvider).setLineStatus(line.id, next);
  }
}

String _clock(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
