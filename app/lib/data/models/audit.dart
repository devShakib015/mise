import 'package:pocketbase/pocketbase.dart';

/// One recorded act. Voids, discounts and cancellations are where money leaves
/// a restaurant unnoticed, so each one is written down with a name against it.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.staffId,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.detail,
    required this.created,
  });

  final String id;
  final String staffId;
  final String action;
  final String entity;
  final String entityId;
  final Map<String, dynamic> detail;
  final DateTime created;

  /// Plain English for the action slug, so a manager is not reading enum names.
  String get label => switch (action) {
        'discount' => 'Gave a discount',
        'void_item' => 'Voided an item',
        'void_payment' => 'Removed a payment',
        'cancel_order' => 'Cancelled a bill',
        'send_to_kitchen' => 'Sent to the kitchen',
        'move_order' => 'Moved a bill',
        'merge_order' => 'Merged two bills',
        'close_shift' => 'Closed a shift',
        'reset_pin' => 'Reset a PIN',
        _ => action.replaceAll('_', ' '),
      };

  /// The handful worth noticing on a busy day.
  bool get isMoneyLeaving =>
      action == 'discount' ||
      action == 'void_item' ||
      action == 'void_payment' ||
      action == 'cancel_order';

  factory AuditEntry.fromRecord(RecordModel r) {
    var detail = <String, dynamic>{};
    final raw = r.get<dynamic>('detail');
    if (raw is Map) detail = Map<String, dynamic>.from(raw);

    return AuditEntry(
      id: r.id,
      staffId: r.getStringValue('staff'),
      action: r.getStringValue('action'),
      entity: r.getStringValue('entity'),
      entityId: r.getStringValue('entity_id'),
      detail: detail,
      created: DateTime.tryParse(r.getStringValue('created'))?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
