import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/message_banner.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/search_picker.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/session.dart';
import '../../setup/currencies.dart';
import 'printers_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _taxRate = TextEditingController();
  final _serviceRate = TextEditingController();
  final _receiptHeader = TextEditingController();
  final _receiptFooter = TextEditingController();

  String _currencyCode = 'USD';
  bool _taxInclusive = false;

  bool _loaded = false;
  bool _busy = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    for (final c in [
      _name, _address, _phone, _taxRate,
      _serviceRate, _receiptHeader, _receiptFooter,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Seeds the form once. Re-seeding on every build would fight the user's
  /// typing every time the session refreshes.
  void _seed(Restaurant r) {
    if (_loaded) return;
    _loaded = true;
    _name.text = r.name;
    _address.text = r.address;
    _phone.text = r.phone;
    _taxRate.text = _trimNumber(r.taxRate);
    _serviceRate.text = _trimNumber(r.serviceChargeRate);
    _receiptHeader.text = r.receiptHeader;
    _receiptFooter.text = r.receiptFooter;
    _currencyCode = r.currencyCode;
    _taxInclusive = r.taxInclusive;
  }

  static String _trimNumber(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

  Future<void> _save() async {
    final tax = double.tryParse(_taxRate.text.trim());
    final service = double.tryParse(_serviceRate.text.trim());

    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Your restaurant needs a name.');
      return;
    }
    if (tax == null || tax < 0 || tax > 100) {
      setState(() => _error = 'Tax rate must be between 0 and 100.');
      return;
    }
    if (service == null || service < 0 || service > 100) {
      setState(() => _error = 'Service charge must be between 0 and 100.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _saved = false;
    });

    final currency = currencyByCode(_currencyCode);
    final error = await ref.read(sessionProvider.notifier).updateRestaurant({
      'name': _name.text.trim(),
      'address': _address.text.trim(),
      'phone': _phone.text.trim(),
      'currency_code': currency.code,
      'currency_symbol': currency.symbol,
      'tax_rate': tax,
      'tax_inclusive': _taxInclusive,
      'service_charge_rate': service,
      'receipt_header': _receiptHeader.text.trim(),
      'receipt_footer': _receiptFooter.text.trim(),
    });

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _saved = error == null;
    });
  }

  Future<void> _pickCurrency() async {
    final picked = await showSearchPicker<CurrencyOption>(
      context: context,
      title: 'Currency',
      options: kCurrencies,
      selected: currencyByCode(_currencyCode),
      labelOf: (c) => c.label,
      trailingOf: (c) => c.symbol,
      searchTextOf: (c) => '${c.code} ${c.name}',
      searchHint: 'Search by code or name',
    );
    if (picked != null && mounted) {
      setState(() {
        _currencyCode = picked.code;
        _saved = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final restaurant = ref.watch(currentRestaurantProvider);
    final staff = ref.watch(currentStaffProvider);

    if (restaurant == null) {
      return const Center(
        child: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }
    _seed(restaurant);

    final canEdit = staff?.role.canManage ?? false;

    return Column(
      children: [
        PageHeader(
          title: 'Settings',
          subtitle: 'How your restaurant identifies itself and what it charges.',
          action: canEdit
              ? FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                )
              : null,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
            children: [
              if (!canEdit)
                const Padding(
                  padding: EdgeInsets.only(bottom: Space.md),
                  child: MessageBanner(
                    tone: BannerTone.info,
                    message: 'Only an owner or manager can change these.',
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: MessageBanner(message: _error!),
                ),
              if (_saved)
                const Padding(
                  padding: EdgeInsets.only(bottom: Space.md),
                  child: MessageBanner(
                    tone: BannerTone.success,
                    message: 'Settings saved.',
                  ),
                ),

              _Section(
                title: 'Restaurant',
                description: 'Printed on receipts and shown across the app.',
                children: [
                  AppField(label: 'Name', controller: _name, enabled: canEdit && !_busy),
                  const SizedBox(height: Space.md),
                  AppField(
                    label: 'Address',
                    controller: _address,
                    hint: 'Optional',
                    enabled: canEdit && !_busy,
                  ),
                  const SizedBox(height: Space.md),
                  AppField(
                    label: 'Phone',
                    controller: _phone,
                    hint: 'Optional',
                    enabled: canEdit && !_busy,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              _Section(
                title: 'Charges',
                description:
                    'Applied server-side to every bill, so a till cannot get '
                    'them wrong.',
                children: [
                  PickerField(
                    label: 'Currency',
                    value: currencyByCode(_currencyCode).label,
                    enabled: canEdit && !_busy,
                    onTap: _pickCurrency,
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppField(
                          label: 'Tax rate',
                          controller: _taxRate,
                          enabled: canEdit && !_busy,
                          suffix: _Percent(color: p.textTertiary),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: AppField(
                          label: 'Service charge',
                          controller: _serviceRate,
                          enabled: canEdit && !_busy,
                          suffix: _Percent(color: p.textTertiary),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  FormSwitch(
                    label: 'Menu prices include tax',
                    description: _taxInclusive
                        ? 'Tax is taken out of the listed price.'
                        : 'Tax is added on top at checkout.',
                    value: _taxInclusive,
                    onChanged: canEdit && !_busy
                        ? (v) => setState(() {
                              _taxInclusive = v;
                              _saved = false;
                            })
                        : null,
                  ),
                ],
              ),

              _Section(
                title: 'Receipts',
                description: 'Extra lines printed above and below the bill.',
                children: [
                  AppField(
                    label: 'Header',
                    controller: _receiptHeader,
                    hint: 'Optional',
                    enabled: canEdit && !_busy,
                  ),
                  const SizedBox(height: Space.md),
                  AppField(
                    label: 'Footer',
                    controller: _receiptFooter,
                    hint: 'Thank you, please come again',
                    enabled: canEdit && !_busy,
                  ),
                ],
              ),

              _Section(
                title: 'Printers',
                description:
                    'Network thermal printers. No driver needed — just the '
                    'address from the printer\'s self-test page.',
                children: [PrintersSection(canEdit: canEdit)],
              ),

              _Section(
                title: 'This device',
                description: 'Only affects this terminal, not the restaurant.',
                children: [
                  _InfoRow(
                    label: 'Server',
                    value: ref.read(sessionProvider.notifier).pb.baseURL,
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            ref.read(sessionProvider.notifier).signOut(),
                        child: const Text('Sign out'),
                      ),
                      const SizedBox(width: Space.xs),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: p.danger),
                        onPressed: () async {
                          final ok = await confirmDestructive(
                            context,
                            title: 'Disconnect this device?',
                            message:
                                'This terminal will forget the server and need '
                                'setting up again. Nothing on the server changes.',
                            confirmLabel: 'Disconnect',
                          );
                          if (ok) {
                            await ref.read(sessionProvider.notifier).forgetServer();
                          }
                        },
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: Radii.large,
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppType.subtitle.copyWith(color: p.textPrimary)),
            const SizedBox(height: 2),
            Text(description, style: AppType.small.copyWith(color: p.textTertiary)),
            const SizedBox(height: Space.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Text(label, style: AppType.body.copyWith(color: p.textSecondary)),
        const Spacer(),
        Text(value, style: AppType.body.copyWith(color: p.textPrimary)),
      ],
    );
  }
}

class _Percent extends StatelessWidget {
  const _Percent({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: Space.sm),
        child: Center(
          widthFactor: 1,
          child: Text('%', style: AppType.body.copyWith(color: color)),
        ),
      );
}
