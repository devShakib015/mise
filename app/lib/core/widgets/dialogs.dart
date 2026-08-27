import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// Confirmation for something that cannot be undone. Names the consequence
/// rather than asking "are you sure?".
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final p = context.palette;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: p.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shell for a create/edit form. Keeps the header, scroll behaviour, error slot
/// and action row identical everywhere so forms never drift apart.
class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    this.onDelete,
    this.saveLabel = 'Save',
    this.busy = false,
    this.error,
    this.width = 460,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final String saveLabel;
  final bool busy;
  final String? error;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: AppType.subtitle.copyWith(color: p.textPrimary)),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 20, color: p.textTertiary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
                child: Text(error!, style: AppType.small.copyWith(color: p.danger)),
              ),
            Divider(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Row(
                children: [
                  if (onDelete != null)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: p.danger),
                      onPressed: busy ? null : onDelete,
                      child: const Text('Delete'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: Space.xs),
                  FilledButton(
                    onPressed: busy ? null : onSave,
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(saveLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled on/off row used inside forms.
class FormSwitch extends StatelessWidget {
  const FormSwitch({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      borderRadius: Radii.medium,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
                  const SizedBox(height: 1),
                  Text(description,
                      style: AppType.small.copyWith(color: p.textSecondary)),
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
