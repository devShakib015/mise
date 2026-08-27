import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// A labelled text field. The label sits above the box rather than floating
/// inside it — easier to scan when a form is being filled in a hurry.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppType.label.copyWith(color: p.textSecondary)),
          const SizedBox(height: Space.xs),
        ],
        SizedBox(
          height: Hit.field,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            autofocus: autofocus,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            maxLength: maxLength,
            style: AppType.body.copyWith(color: p.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefix,
              suffixIcon: suffix,
              counterText: '',
              errorText: null,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: Space.xxs + 2),
          Text(errorText!, style: AppType.small.copyWith(color: p.danger)),
        ] else if (helper != null) ...[
          const SizedBox(height: Space.xxs + 2),
          Text(helper!, style: AppType.small.copyWith(color: p.textTertiary)),
        ],
      ],
    );
  }
}
