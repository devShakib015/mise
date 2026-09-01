import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/printing/kitchen_ticket.dart';
import '../../core/printing/printer_client.dart';
import '../../core/printing/receipt.dart';
import '../../data/models/menu.dart';
import '../../data/models/service.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';

/// Prints a docket to whichever stations have to make something.
///
/// Routed by the category's station, so the bar gets the drinks and the kitchen
/// gets the food rather than both printing the whole order. Returns a short
/// line for the snackbar, or empty when there was nothing to print.
///
/// Deliberately never throws. A printer that is off, unplugged or out of paper
/// must not stop an order reaching the kitchen screen — the screen is the
/// source of truth and the paper is a convenience.
Future<String> printDockets(
  WidgetRef ref, {
  required Order order,
  required List<OrderLine> lines,
}) async {
  if (lines.isEmpty || !PrinterClient.isSupported) return '';

  final printers = (ref.read(printersProvider).value ?? const <Printer>[])
      .where((p) => p.active && p.role != PrinterRole.receipt)
      .toList();
  if (printers.isEmpty) return '';

  final items = ref.read(menuItemsProvider).value ?? const <MenuItem>[];
  final categories = ref.read(categoriesProvider).value ?? const <Category>[];
  final tables = ref.read(tablesProvider).value ?? const <DiningTable>[];
  final staffName = ref.read(currentStaffProvider)?.name ?? '';
  final tableLabel =
      tables.where((t) => t.id == order.tableId).firstOrNull?.label ?? '';

  final stationOf = <String, Station>{};
  for (final c in categories) {
    stationOf[c.id] = c.station;
  }
  Station stationFor(OrderLine line) {
    final item = items.where((i) => i.id == line.menuItemId).firstOrNull;
    // An item whose category has gone missing still has to be made by someone,
    // and the kitchen is the safer guess.
    return item == null ? Station.kitchen : (stationOf[item.categoryId] ?? Station.kitchen);
  }

  final done = <String>[];
  for (final printer in printers) {
    final wanted = printer.role == PrinterRole.bar ? Station.bar : Station.kitchen;
    final forStation = lines.where((l) => stationFor(l) == wanted).toList();
    if (forStation.isEmpty) continue;

    final docket = KitchenTicket(
      order: order,
      lines: forStation,
      width: PaperWidth.parse(printer.paperWidth),
      tableLabel: tableLabel,
      staffName: staffName,
      station: printer.role.label,
    );

    final result = await PrinterClient.send(
      host: printer.host,
      port: printer.port,
      bytes: docket.escPos(),
    );
    if (result.success) done.add(printer.name);
  }

  if (done.isEmpty) return '';
  return done.length == 1
      ? 'printed at ${done.first}'
      : 'printed at ${done.length} stations';
}
