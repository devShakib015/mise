import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/centered_panel.dart';
import '../../core/widgets/message_banner.dart';
import '../../data/session.dart';

/// Staff sign-in. The PIN goes in on a keypad rather than a text field — at a
/// terminal mid-service nobody wants a software keyboard covering the screen.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, required this.venueName});

  final String venueName;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  static const _maxPin = 8;

  final _username = TextEditingController();
  String _pin = '';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  void _press(String digit) {
    if (_busy || _pin.length >= _maxPin) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_busy) return;

    if (_username.text.trim().isEmpty) {
      setState(() => _error = 'Enter your username.');
      return;
    }
    if (_pin.length < 4) {
      setState(() => _error = 'Your PIN is at least 4 digits.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error =
        await ref.read(sessionProvider.notifier).signIn(_username.text, _pin);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error != null) _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return CenteredPanel(
      maxWidth: 400,
      subtitle: widget.venueName.isEmpty ? null : widget.venueName,
      footer: TextButton(
        onPressed: _busy
            ? null
            : () => ref.read(sessionProvider.notifier).forgetServer(),
        child: const Text('Use a different server'),
      ),
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          final ch = event.character;
          if (ch != null && ch.length == 1 && '0123456789'.contains(ch)) {
            _press(ch);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _backspace();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            _submit();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sign in', style: AppType.title.copyWith(color: p.textPrimary)),
            const SizedBox(height: Space.lg),

            AppField(
              label: 'Username',
              controller: _username,
              hint: 'shakib',
              enabled: !_busy,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.-]')),
              ],
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: Space.lg),
            Text('PIN', style: AppType.label.copyWith(color: p.textSecondary)),
            const SizedBox(height: Space.sm),
            _PinDots(length: _pin.length, max: _maxPin),

            if (_error != null) ...[
              const SizedBox(height: Space.md),
              MessageBanner(message: _error!),
            ],

            const SizedBox(height: Space.lg),
            _Keypad(
              enabled: !_busy,
              onDigit: _press,
              onBackspace: _backspace,
              onSubmit: _submit,
              busy: _busy,
            ),
          ],
        ),
      ),
    );
  }
}

/// Filled dots rather than the digits themselves — a POS screen faces the room.
class _PinDots extends StatelessWidget {
  const _PinDots({required this.length, required this.max});

  final int length;
  final int max;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Show at least four slots, growing as a longer PIN is typed.
    final slots = length < 4 ? 4 : (length >= max ? max : length + 1);

    return SizedBox(
      height: 20,
      child: Row(
        children: [
          for (var i = 0; i < slots; i++)
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: AnimatedContainer(
                duration: Motion.instant,
                width: i < length ? 14 : 10,
                height: i < length ? 14 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < length ? p.brand : Colors.transparent,
                  border: i < length ? null : Border.all(color: p.borderStrong, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.busy,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    Widget key(String label) => _KeypadKey(
          label: label,
          enabled: enabled,
          onTap: () => onDigit(label),
        );

    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Row(
              children: [
                for (final d in row) ...[
                  Expanded(child: key(d)),
                  if (d != row.last) const SizedBox(width: Space.xs),
                ],
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _KeypadKey(
                icon: Icons.backspace_outlined,
                enabled: enabled,
                onTap: onBackspace,
                subdued: true,
              ),
            ),
            const SizedBox(width: Space.xs),
            Expanded(child: key('0')),
            const SizedBox(width: Space.xs),
            Expanded(
              child: _KeypadKey(
                icon: Icons.arrow_forward_rounded,
                enabled: enabled,
                onTap: onSubmit,
                primary: true,
                busy: busy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    this.label,
    this.icon,
    required this.enabled,
    required this.onTap,
    this.primary = false,
    this.subdued = false,
    this.busy = false,
  });

  final String? label;
  final IconData? icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool primary;
  final bool subdued;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final bg = primary
        ? p.brand
        : subdued
            ? Colors.transparent
            : p.surfaceSunken;
    final fg = primary ? p.onBrand : p.textPrimary;

    return SizedBox(
      height: 54,
      child: Material(
        color: enabled ? bg : bg.withValues(alpha: 0.5),
        borderRadius: Radii.medium,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.medium,
          side: BorderSide(
            color: primary ? Colors.transparent : p.border,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                  )
                : label != null
                    ? Text(
                        label!,
                        style: AppType.subtitle.copyWith(
                          color: enabled ? fg : p.textTertiary,
                          fontSize: 20,
                        ),
                      )
                    : Icon(icon,
                        size: 20, color: enabled ? fg : p.textTertiary),
          ),
        ),
      ),
    );
  }
}
