import 'dart:convert';

import '../../data/models/service.dart';
import 'receipt.dart' show PaperWidth;

/// The docket that goes to the kitchen or the bar.
///
/// Deliberately not a receipt. No prices, no tax, no totals — none of it helps
/// anyone cook. What matters is what to make, how many, and anything that will
/// ruin the dish if missed, so notes get the largest type on the paper.
class KitchenTicket {
  const KitchenTicket({
    required this.order,
    required this.lines,
    required this.width,
    this.tableLabel = '',
    this.staffName = '',
    this.station = '',
    this.printedAt,
  });

  final Order order;

  /// Only the lines this station has to make.
  final List<OrderLine> lines;
  final PaperWidth width;
  final String tableLabel;
  final String staffName;

  /// "Kitchen" or "Bar", printed so a docket cannot be picked up by the wrong
  /// station.
  final String station;
  final DateTime? printedAt;

  int get _cols => width.columns;

  String _centre(String s) {
    if (s.length >= _cols) return s.substring(0, _cols);
    return ' ' * ((_cols - s.length) ~/ 2) + s;
  }

  String _row(String left, String right) {
    final space = _cols - right.length;
    if (space < 1) return right.padLeft(_cols);
    final l = left.length > space - 1 ? left.substring(0, space - 1) : left;
    return l.padRight(space) + right;
  }

  List<String> _wrap(String text, {String indent = ''}) {
    final out = <String>[];
    var current = indent;
    for (final w in text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
      if (current.trim().isEmpty) {
        current = indent + w;
      } else if (current.length + 1 + w.length <= _cols) {
        current = '$current $w';
      } else {
        out.add(current);
        current = indent + w;
      }
    }
    if (current.trim().isNotEmpty) out.add(current);
    return out;
  }

  static String _time(DateTime d) {
    two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  String text() {
    final when = printedAt ?? DateTime.now();
    final out = <String>[];

    if (station.isNotEmpty) out.add(_centre(station.toUpperCase()));
    out.add(_centre(tableLabel.isNotEmpty ? 'TABLE $tableLabel' : order.type.label.toUpperCase()));
    out.add('');
    out.add(_row('#${order.number}', _time(when)));
    if (staffName.isNotEmpty) out.add(staffName);
    out.add('=' * _cols);

    for (final line in lines) {
      if (line.isVoid) continue;
      // Wrapped, not truncated: a dish whose name runs long still has to be
      // readable, and cutting it off is how the wrong thing gets cooked.
      out.addAll(_wrap('${line.qty} x ${line.name}'.toUpperCase(), indent: '  '));
      if (line.modifiers.isNotEmpty) {
        out.addAll(_wrap(line.modifiers.map((m) => m.name).join(', '), indent: '   '));
      }
      if (line.note.isNotEmpty) {
        // The one thing that ruins a plate if it is missed.
        out.addAll(_wrap('** ${line.note.toUpperCase()} **', indent: '   '));
      }
      out.add('');
    }

    out.add('-' * _cols);
    return out.join('\n');
  }

  List<int> escPos() {
    final body = <int>[];
    void raw(List<int> b) => body.addAll(b);
    void write(String s) => raw(
        latin1.encode(s.replaceAll(RegExp(r'[^\x20-\x7E\n]'), '?')));

    raw([0x1B, 0x40]); // initialise
    raw([0x1B, 0x61, 0x01]); // centre

    final all = text().split('\n');
    var i = 0;

    // Station and table lead the docket at double size — a chef reads these
    // from the rail, not from arm's length.
    final headerCount = station.isNotEmpty ? 2 : 1;
    raw([0x1D, 0x21, 0x11]); // double width and height
    raw([0x1B, 0x45, 0x01]);
    for (; i < headerCount && i < all.length; i++) {
      write('${all[i].trim()}\n');
    }
    raw([0x1B, 0x45, 0x00]);
    raw([0x1D, 0x21, 0x00]);
    raw([0x1B, 0x61, 0x00]); // left

    for (; i < all.length; i++) {
      final line = all[i];
      final isItem = RegExp(r'^\d+ X ').hasMatch(line);
      final isNote = line.trimLeft().startsWith('**');

      // Items get double height; notes get bold. Both read at a glance.
      if (isItem) raw([0x1D, 0x21, 0x01]);
      if (isNote) raw([0x1B, 0x45, 0x01]);
      write('$line\n');
      if (isNote) raw([0x1B, 0x45, 0x00]);
      if (isItem) raw([0x1D, 0x21, 0x00]);
    }

    raw([0x0A, 0x0A, 0x0A]);
    raw([0x1D, 0x56, 0x42, 0x00]); // partial cut
    return body;
  }
}
