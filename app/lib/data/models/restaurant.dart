import 'package:pocketbase/pocketbase.dart';

/// The venue's identity and money rules.
///
/// The rates here are mirrored server-side; the copies are for display only.
/// Every total the app shows comes back from the server, never from this class.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.taxRate,
    required this.taxInclusive,
    required this.serviceChargeRate,
    required this.setupComplete,
    this.address = '',
    this.phone = '',
    this.logo = '',
    this.receiptHeader = '',
    this.receiptFooter = '',
  });

  final String id;
  final String name;
  final String currencyCode;
  final String currencySymbol;

  /// Percentage, e.g. 7.5 for 7.5%.
  final double taxRate;

  /// True when menu prices already contain the tax, so it is extracted from the
  /// total rather than added on top.
  final bool taxInclusive;
  final double serviceChargeRate;
  final bool setupComplete;

  final String address;
  final String phone;
  final String logo;
  final String receiptHeader;
  final String receiptFooter;

  factory Restaurant.fromRecord(RecordModel r) => Restaurant(
        id: r.id,
        name: r.getStringValue('name'),
        currencyCode: r.getStringValue('currency_code'),
        currencySymbol: r.getStringValue('currency_symbol'),
        taxRate: r.getDoubleValue('tax_rate'),
        taxInclusive: r.getBoolValue('tax_inclusive'),
        serviceChargeRate: r.getDoubleValue('service_charge_rate'),
        setupComplete: r.getBoolValue('setup_complete'),
        address: r.getStringValue('address'),
        phone: r.getStringValue('phone'),
        logo: r.getStringValue('logo'),
        receiptHeader: r.getStringValue('receipt_header'),
        receiptFooter: r.getStringValue('receipt_footer'),
      );
}
