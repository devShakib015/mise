import '../../data/models/service.dart';
import '../../data/models/staff.dart';

/// One row of a breakdown: a label, how many, and how much.
class BreakdownRow {
  const BreakdownRow({
    required this.label,
    required this.count,
    required this.value,
  });

  final String label;
  final int count;
  final double value;
}

/// Sales cut three ways: what sold, who sold it, and when.
///
/// Built from the same settled bills the headline figures use, so the parts
/// always add up to the whole.
class SalesBreakdown {
  const SalesBreakdown({
    required this.byItem,
    required this.byStaff,
    required this.byHour,
    required this.busiestHour,
  });

  /// Items sold, biggest earner first.
  final List<BreakdownRow> byItem;

  /// Staff, by what they took.
  final List<BreakdownRow> byStaff;

  /// Takings for each hour that had any, earliest first.
  final List<BreakdownRow> byHour;

  /// Hour of day with the highest takings, or null on an empty day.
  final int? busiestHour;

  static const empty = SalesBreakdown(
    byItem: [],
    byStaff: [],
    byHour: [],
    busiestHour: null,
  );

  factory SalesBreakdown.from({
    required List<Order> orders,
    required List<OrderLine> lines,
    required List<Staff> staff,
  }) {
    // Only settled bills count, matching the headline report exactly.
    final settled = {
      for (final o in orders)
        if (o.status == OrderStatus.paid) o.id: o,
    };
    if (settled.isEmpty) return empty;

    // ---- what sold -------------------------------------------------------
    final itemQty = <String, int>{};
    final itemValue = <String, double>{};
    for (final l in lines) {
      if (l.isVoid) continue;
      if (!settled.containsKey(l.orderId)) continue;
      itemQty[l.name] = (itemQty[l.name] ?? 0) + l.qty;
      itemValue[l.name] = (itemValue[l.name] ?? 0) + l.lineTotal;
    }

    final byItem = [
      for (final name in itemQty.keys)
        BreakdownRow(
          label: name,
          count: itemQty[name]!,
          value: _round(itemValue[name] ?? 0),
        ),
    ]..sort((a, b) => b.value.compareTo(a.value));

    // ---- who sold it -----------------------------------------------------
    final names = {for (final s in staff) s.id: s.name};
    final staffBills = <String, int>{};
    final staffValue = <String, double>{};
    for (final o in settled.values) {
      staffBills[o.staffId] = (staffBills[o.staffId] ?? 0) + 1;
      staffValue[o.staffId] = (staffValue[o.staffId] ?? 0) + o.total;
    }

    final byStaff = [
      for (final id in staffBills.keys)
        BreakdownRow(
          // A member who has since been removed still has their sales; showing
          // "Removed" beats showing a raw record id.
          label: names[id] ?? 'Removed',
          count: staffBills[id]!,
          value: _round(staffValue[id] ?? 0),
        ),
    ]..sort((a, b) => b.value.compareTo(a.value));

    // ---- when ------------------------------------------------------------
    // Keyed on when the bill closed: that is when the money arrived, and it is
    // what the headline figures are keyed on too.
    final hourBills = <int, int>{};
    final hourValue = <int, double>{};
    for (final o in settled.values) {
      final hour = (o.closedAt ?? o.created).hour;
      hourBills[hour] = (hourBills[hour] ?? 0) + 1;
      hourValue[hour] = (hourValue[hour] ?? 0) + o.total;
    }

    final hours = hourBills.keys.toList()..sort();
    final byHour = [
      for (final h in hours)
        BreakdownRow(
          label: _hourLabel(h),
          count: hourBills[h]!,
          value: _round(hourValue[h] ?? 0),
        ),
    ];

    int? busiest;
    var best = 0.0;
    for (final e in hourValue.entries) {
      if (e.value > best) {
        best = e.value;
        busiest = e.key;
      }
    }

    return SalesBreakdown(
      byItem: byItem,
      byStaff: byStaff,
      byHour: byHour,
      busiestHour: busiest,
    );
  }

  static String _hourLabel(int h) {
    final from = h.toString().padLeft(2, '0');
    final to = ((h + 1) % 24).toString().padLeft(2, '0');
    return '$from:00–$to:00';
  }

  static double _round(double v) => (v * 100).round() / 100;
}
