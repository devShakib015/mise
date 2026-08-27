import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/centered_panel.dart';
import '../../core/widgets/message_banner.dart';
import '../../core/widgets/search_picker.dart';
import '../../data/session.dart';
import 'currencies.dart';

/// First run. Three steps: what the place is called, how it charges, and who
/// owns it. Nothing here needs a terminal or a support call.
class SetupWizard extends ConsumerStatefulWidget {
  const SetupWizard({super.key});

  @override
  ConsumerState<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends ConsumerState<SetupWizard> {
  static const _steps = ['Restaurant', 'Charges', 'Owner'];

  int _step = 0;
  bool _busy = false;
  String? _error;

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();

  String _currencyCode = 'USD';
  final _taxRate = TextEditingController(text: '0');
  final _serviceRate = TextEditingController(text: '0');
  bool _taxInclusive = false;

  final _ownerName = TextEditingController();
  final _username = TextEditingController();
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();

  final _fieldErrors = <String, String>{};

  @override
  void dispose() {
    for (final c in [
      _name, _address, _phone, _taxRate, _serviceRate,
      _ownerName, _username, _pin, _pinConfirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  bool _validateStep() {
    _fieldErrors.clear();

    if (_step == 0) {
      if (_name.text.trim().isEmpty) {
        _fieldErrors['name'] = 'Your restaurant needs a name.';
      }
    } else if (_step == 1) {
      final tax = double.tryParse(_taxRate.text.trim());
      final service = double.tryParse(_serviceRate.text.trim());
      if (tax == null || tax < 0 || tax > 100) {
        _fieldErrors['tax'] = 'Enter a percentage between 0 and 100.';
      }
      if (service == null || service < 0 || service > 100) {
        _fieldErrors['service'] = 'Enter a percentage between 0 and 100.';
      }
    } else {
      if (_ownerName.text.trim().isEmpty) {
        _fieldErrors['ownerName'] = 'Who owns this restaurant?';
      }
      final user = _username.text.trim().toLowerCase();
      if (user.isEmpty) {
        _fieldErrors['username'] = 'Pick a username to sign in with.';
      } else if (!RegExp(r'^[a-z0-9_.-]+$').hasMatch(user)) {
        _fieldErrors['username'] = 'Letters, numbers, dot, dash or underscore only.';
      }
      if (_pin.text.length < 4) {
        _fieldErrors['pin'] = 'Use at least 4 digits.';
      } else if (_pin.text != _pinConfirm.text) {
        _fieldErrors['pinConfirm'] = 'The two PINs do not match.';
      }
    }

    setState(() {});
    return _fieldErrors.isEmpty;
  }

  Future<void> _next() async {
    if (_busy) return;
    if (!_validateStep()) return;

    if (_step < _steps.length - 1) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final currency = currencyByCode(_currencyCode);
    final error = await ref.read(sessionProvider.notifier).runSetup(
          restaurantName: _name.text,
          ownerName: _ownerName.text,
          ownerUsername: _username.text,
          ownerPin: _pin.text,
          address: _address.text,
          phone: _phone.text,
          currencyCode: currency.code,
          currencySymbol: currency.symbol,
          taxRate: _num(_taxRate),
          taxInclusive: _taxInclusive,
          serviceChargeRate: _num(_serviceRate),
        );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
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
      setState(() => _currencyCode = picked.code);
    }
  }

  void _back() {
    if (_step == 0 || _busy) return;
    setState(() {
      _step--;
      _error = null;
      _fieldErrors.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return CenteredPanel(
      maxWidth: 520,
      subtitle: 'Setting up',
      footer: TextButton(
        onPressed: _busy
            ? null
            : () => ref.read(sessionProvider.notifier).forgetServer(),
        child: const Text('Use a different server'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBar(steps: _steps, current: _step),
          const SizedBox(height: Space.xl),

          AnimatedSize(
            duration: Motion.fast,
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: switch (_step) {
              0 => _restaurantStep(p),
              1 => _chargesStep(p),
              _ => _ownerStep(p),
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: Space.md),
            MessageBanner(message: _error!),
          ],

          const SizedBox(height: Space.xl),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _back,
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: Space.sm),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _busy ? null : _next,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(_step == _steps.length - 1
                          ? 'Create restaurant'
                          : 'Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- steps

  Widget _restaurantStep(AppPalette p) => Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Heading('What is this place called?',
              'It goes on receipts and on every screen.'),
          AppField(
            label: 'Restaurant name',
            controller: _name,
            hint: 'The Ember',
            autofocus: true,
            errorText: _fieldErrors['name'],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Space.md),
          AppField(
            label: 'Address',
            controller: _address,
            hint: 'Optional — printed on receipts',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Space.md),
          AppField(
            label: 'Phone',
            controller: _phone,
            hint: 'Optional',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _next(),
          ),
        ],
      );

  Widget _chargesStep(AppPalette p) => Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Heading('How do you charge?',
              'All of this can be changed later in settings.'),
          PickerField(
            label: 'Currency',
            value: currencyByCode(_currencyCode).label,
            enabled: !_busy,
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
                  suffix: _PercentSuffix(color: p.textTertiary),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  errorText: _fieldErrors['tax'],
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: AppField(
                  label: 'Service charge',
                  controller: _serviceRate,
                  suffix: _PercentSuffix(color: p.textTertiary),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  errorText: _fieldErrors['service'],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          _InclusiveToggle(
            value: _taxInclusive,
            onChanged: _busy ? null : (v) => setState(() => _taxInclusive = v),
          ),
        ],
      );

  Widget _ownerStep(AppPalette p) => Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Heading('Create the owner account',
              'You will sign in with this username and PIN.'),
          AppField(
            label: 'Your name',
            controller: _ownerName,
            hint: 'Shakib',
            autofocus: true,
            errorText: _fieldErrors['ownerName'],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Space.md),
          AppField(
            label: 'Username',
            controller: _username,
            hint: 'shakib',
            errorText: _fieldErrors['username'],
            helper: 'Short and easy to type at a busy terminal.',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.-]')),
            ],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppField(
                  label: 'PIN',
                  controller: _pin,
                  obscure: true,
                  maxLength: 8,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: _fieldErrors['pin'],
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: AppField(
                  label: 'Confirm PIN',
                  controller: _pinConfirm,
                  obscure: true,
                  maxLength: 8,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: _fieldErrors['pinConfirm'],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _next(),
                ),
              ),
            ],
          ),
        ],
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppType.subtitle.copyWith(color: p.textPrimary)),
        const SizedBox(height: Space.xxs),
        Text(subtitle, style: AppType.small.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.lg),
      ],
    );
  }
}

class _PercentSuffix extends StatelessWidget {
  const _PercentSuffix({required this.color});

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

/// Whether menu prices already contain tax. Worth spelling out — getting this
/// backwards silently misprices every item in the venue.
class _InclusiveToggle extends StatelessWidget {
  const _InclusiveToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: Radii.medium,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menu prices include tax',
                      style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    value
                        ? 'Tax is taken out of the listed price.'
                        : 'Tax is added on top at checkout.',
                    style: AppType.small.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.steps, required this.current});

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: Space.xs),
                color: i <= current ? p.brand : p.border,
              ),
            ),
          _StepDot(
            index: i,
            label: steps[i],
            done: i < current,
            active: i == current,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
  });

  final int index;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = done || active;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Motion.fast,
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? p.brand : Colors.transparent,
            border: Border.all(color: on ? p.brand : p.borderStrong, width: 1.5),
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, size: 15, color: p.onBrand)
                : Text(
                    '${index + 1}',
                    style: AppType.caption.copyWith(
                      color: active ? p.onBrand : p.textTertiary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: Space.xxs + 2),
        Text(
          label,
          style: AppType.caption.copyWith(
            color: on ? p.textPrimary : p.textTertiary,
          ),
        ),
      ],
    );
  }
}
