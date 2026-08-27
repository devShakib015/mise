import 'dart:convert';

import '../../data/models/money.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/service.dart';

/// Paper width in characters. 58mm rolls fit 32, 80mm rolls fit 48.
enum PaperWidth {
  mm58(32),
  mm80(48);

  const PaperWidth(this.columns);

  final int columns;

  static PaperWidth parse(String raw) =>
      raw == '58' ? PaperWidth.mm58 : PaperWidth.mm80;
}

/// Builds a receipt as plain text and as ESC/POS bytes.
///
/// The text form is what the preview shows and what the tests assert against;
/// the byte form is the same text with control codes woven through it. Keeping
/// them derived from one layout means the preview cannot drift from the print.
class ReceiptBuilder {
  const ReceiptBuilder({
    required this.restaurant,
    required this.order,
    required this.lines,
    required this.payments,
    required this.width,
    this.staffName = '',
    this.tableLabel = '',
    this.printedAt,
  });

  final Restaurant restaurant;
  final Order order;
  final List<OrderLine> lines;
  final List<Payment> payments;
  final PaperWidth width;
  final String staffName;
  final String tableLabel;
  final DateTime? printedAt;

  int get _cols => width.columns;

  /// Thermal printers speak code pages, not Unicode. A symbol like ৳ would come
  /// out as noise, so anything outside ASCII falls back to the currency code,
  /// which every printer can render and no diner can misread.
  String get _money =>
      _isAscii(restaurant.currencySymbol) ? restaurant.currencySymbol : '';

  String get _moneySuffix =>
      _isAscii(restaurant.currencySymbol) ? '' : ' ${restaurant.currencyCode}';

  static bool _isAscii(String s) => s.codeUnits.every((c) => c < 128);

  String _amount(double v) =>
      '$_money${v.toStringAsFixed(2)}$_moneySuffix';

  /// Left text and right text on one line, padded apart. If they cannot both
  /// fit, the left is trimmed — the number is the part that must survive.
  String _row(String left, String right) {
    final space = _cols - right.length;
    if (space < 1) return right.padLeft(_cols);
    final l = left.length > space - 1 ? left.substring(0, space - 1) : left;
    return l.padRight(space) + right;
  }

  String _centre(String s) {
    if (s.length >= _cols) return s.substring(0, _cols);
    final pad = (_cols - s.length) ~/ 2;
    return ' ' * pad + s;
  }

  String _rule([String ch = '-']) => ch * _cols;

  /// Wraps text to the paper width, indenting continuation lines.
  List<String> _wrap(String text, {String indent = ''}) {
    final out = <String>[];
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    var current = indent;

    for (final w in words) {
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

  static String _stamp(DateTime d) {
    two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }

  /// The receipt as plain text, exactly as it will print.
  String text() {
    final when = printedAt ?? DateTime.now();
    final out = <String>[];

    out.add(_centre(restaurant.name));
    if (restaurant.address.isNotEmpty) out.addAll(_wrap(restaurant.address).map(_centre));
    if (restaurant.phone.isNotEmpty) out.add(_centre(restaurant.phone));
    if (restaurant.receiptHeader.isNotEmpty) {
      out.add('');
      out.addAll(_wrap(restaurant.receiptHeader).map(_centre));
    }

    out.add('');
    out.add(_row('Bill #${order.number}', _stamp(when)));
    out.add(_row(
      tableLabel.isNotEmpty ? 'Table $tableLabel' : order.type.label,
      staffName,
    ));
    if (order.guestCount > 0) {
      out.add('Guests: ${order.guestCount}');
    }
    out.add(_rule());

    for (final line in lines) {
      if (line.isVoid) continue;
      out.add(_row('${line.qty} x ${line.name}', _amount(line.lineTotal)));
      if (line.modifiers.isNotEmpty) {
        out.addAll(_wrap(line.modifiers.map((m) => m.name).join(', '),
            indent: '    '));
      }
      if (line.note.isNotEmpty) {
        out.addAll(_wrap('* ${line.note}', indent: '    '));
      }
    }

    out.add(_rule());
    out.add(_row('Subtotal', _amount(order.subtotal)));
    if (order.discountAmount > 0) {
      out.add(_row('Discount', '-${_amount(order.discountAmount)}'));
    }
    if (order.serviceAmount > 0) {
      out.add(_row(
        'Service ${_pct(restaurant.serviceChargeRate)}',
        _amount(order.serviceAmount),
      ));
    }
    if (order.taxAmount > 0) {
      out.add(_row(
        restaurant.taxInclusive
            ? 'Tax ${_pct(restaurant.taxRate)} (incl)'
            : 'Tax ${_pct(restaurant.taxRate)}',
        _amount(order.taxAmount),
      ));
    }
    out.add(_rule('='));
    out.add(_row('TOTAL', _amount(order.total)));

    if (payments.isNotEmpty) {
      out.add('');
      for (final p in payments) {
        out.add(_row(p.method.label, _amount(p.amount)));
        if (p.method.isCash && p.tendered > 0) {
          out.add(_row('  Tendered', _amount(p.tendered)));
          out.add(_row('  Change', _amount(p.changeDue)));
        }
        if (p.reference.isNotEmpty) {
          out.add('  Ref: ${p.reference}');
        }
      }
      final owing = order.total - order.paidAmount;
      if (owing > 0.004) {
        out.add(_row('STILL OWING', _amount(owing)));
      }
    }

    if (restaurant.receiptFooter.isNotEmpty) {
      out.add('');
      out.addAll(_wrap(restaurant.receiptFooter).map(_centre));
    }

    return out.join('\n');
  }

  static String _pct(double v) =>
      '${v % 1 == 0 ? v.toStringAsFixed(0) : v.toString()}%';

  /// The same receipt as ESC/POS bytes, ready for a printer on port 9100.
  List<int> escPos() {
    final body = <int>[];

    void raw(List<int> bytes) => body.addAll(bytes);
    void write(String s) {
      // Latin-1 covers the ASCII this builder emits; anything stranger is
      // replaced rather than sent as bytes the printer would misread.
      raw(latin1.encode(s.replaceAll(RegExp(r'[^\x20-\x7E\n]'), '?')));
    }

    raw([0x1B, 0x40]); // initialise

    final all = text().split('\n');

    // The venue name is the one thing worth double-height.
    raw([0x1B, 0x61, 0x01]); // centre
    raw([0x1D, 0x21, 0x01]); // double height
    raw([0x1B, 0x45, 0x01]); // bold on
    write('${restaurant.name}\n');
    raw([0x1B, 0x45, 0x00]); // bold off
    raw([0x1D, 0x21, 0x00]); // normal size
    raw([0x1B, 0x61, 0x00]); // left

    // The name is already printed, so skip its line in the body.
    for (final line in all.skip(1)) {
      final isTotal = line.startsWith('TOTAL');
      if (isTotal) raw([0x1B, 0x45, 0x01]);
      write('$line\n');
      if (isTotal) raw([0x1B, 0x45, 0x00]);
    }

    raw([0x0A, 0x0A, 0x0A]); // feed clear of the tear bar
    raw([0x1D, 0x56, 0x42, 0x00]); // partial cut

    return body;
  }
}
