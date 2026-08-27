/// A currency a venue can price in.
class CurrencyOption {
  const CurrencyOption(this.code, this.symbol, this.name);

  final String code;
  final String symbol;
  final String name;

  String get label => '$code  ·  $name';
}

/// Deliberately a short list of common currencies rather than all ~180 ISO
/// codes — a setup wizard is not the place to scroll. Anything missing can be
/// typed in afterwards from settings.
const kCurrencies = <CurrencyOption>[
  CurrencyOption('USD', r'$', 'US Dollar'),
  CurrencyOption('EUR', '€', 'Euro'),
  CurrencyOption('GBP', '£', 'Pound Sterling'),
  CurrencyOption('BDT', '৳', 'Bangladeshi Taka'),
  CurrencyOption('INR', '₹', 'Indian Rupee'),
  CurrencyOption('PKR', '₨', 'Pakistani Rupee'),
  CurrencyOption('AED', 'AED', 'UAE Dirham'),
  CurrencyOption('SAR', 'SAR', 'Saudi Riyal'),
  CurrencyOption('MYR', 'RM', 'Malaysian Ringgit'),
  CurrencyOption('SGD', r'S$', 'Singapore Dollar'),
  CurrencyOption('AUD', r'A$', 'Australian Dollar'),
  CurrencyOption('CAD', r'C$', 'Canadian Dollar'),
  CurrencyOption('JPY', '¥', 'Japanese Yen'),
  CurrencyOption('CNY', '¥', 'Chinese Yuan'),
  CurrencyOption('TRY', '₺', 'Turkish Lira'),
  CurrencyOption('NGN', '₦', 'Nigerian Naira'),
  CurrencyOption('ZAR', 'R', 'South African Rand'),
  CurrencyOption('KES', 'KSh', 'Kenyan Shilling'),
  CurrencyOption('EGP', 'E£', 'Egyptian Pound'),
  CurrencyOption('PHP', '₱', 'Philippine Peso'),
  CurrencyOption('IDR', 'Rp', 'Indonesian Rupiah'),
  CurrencyOption('THB', '฿', 'Thai Baht'),
  CurrencyOption('VND', '₫', 'Vietnamese Dong'),
  CurrencyOption('BRL', r'R$', 'Brazilian Real'),
  CurrencyOption('MXN', r'MX$', 'Mexican Peso'),
];

CurrencyOption currencyByCode(String code) => kCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => kCurrencies.first,
    );
