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
import '../../../data/models/staff.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../data/session.dart';

class StaffPage extends ConsumerWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffListProvider);
    final me = ref.watch(currentStaffProvider);

    return Column(
      children: [
        PageHeader(
          title: 'Staff',
          subtitle: 'Who can sign in, and what they are allowed to do.',
          action: FilledButton.icon(
            onPressed: () => _add(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add someone'),
          ),
        ),
        Expanded(
          child: AsyncView<List<Staff>>(
            value: staff,
            onRetry: () => ref.invalidate(staffListProvider),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.badge_outlined,
                  title: 'Nobody here yet',
                  message: 'Add your waiters, cashiers and kitchen staff.',
                );
              }

              // Grouped by role so the shape of the team is legible at a glance.
              final byRole = <StaffRole, List<Staff>>{};
              for (final s in list) {
                byRole.putIfAbsent(s.role, () => []).add(s);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final role in StaffRole.values)
                            if (byRole[role] != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: Space.xs, bottom: Space.xs),
                                child: Text(
                                  '${role.label.toUpperCase()}S'
                                      .replaceAll('SS', 'S'),
                                  style: AppType.overline
                                      .copyWith(color: context.palette.textTertiary),
                                ),
                              ),
                              for (final s in byRole[role]!)
                                _StaffRow(
                                  staff: s,
                                  isMe: s.id == me?.id,
                                  onTap: () => _edit(context, s),
                                ),
                              const SizedBox(height: Space.sm),
                            ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const _StaffDialog(),
      );

  Future<void> _edit(BuildContext context, Staff staff) => showDialog<void>(
        context: context,
        builder: (_) => _StaffDialog(existing: staff),
      );
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.staff,
    required this.isMe,
    required this.onTap,
  });

  final Staff staff;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: p.surface,
        borderRadius: Radii.large,
        child: InkWell(
          borderRadius: Radii.large,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.large,
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: staff.active ? p.brandSubtle : p.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    staff.initials,
                    style: AppType.label.copyWith(
                      color: staff.active ? p.brand : p.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              staff.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.bodyStrong.copyWith(
                                color: staff.active ? p.textPrimary : p.textTertiary,
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: Space.xs),
                            Text('you',
                                style: AppType.caption.copyWith(color: p.brand)),
                          ],
                        ],
                      ),
                      Text(
                        '@${staff.username}${staff.active ? '' : ' · switched off'}',
                        style: AppType.small.copyWith(color: p.textTertiary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: p.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffDialog extends ConsumerStatefulWidget {
  const _StaffDialog({this.existing});

  final Staff? existing;

  @override
  ConsumerState<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<_StaffDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _username =
      TextEditingController(text: widget.existing?.username ?? '');
  final _pin = TextEditingController();
  late StaffRole _role = widget.existing?.role ?? StaffRole.waiter;
  late bool _active = widget.existing?.active ?? true;

  bool _busy = false;
  String? _error;
  String? _notice;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give them a name.');
      return;
    }

    if (_isNew) {
      final user = _username.text.trim().toLowerCase();
      if (user.isEmpty) {
        setState(() => _error = 'Pick a username for them to sign in with.');
        return;
      }
      if (!RegExp(r'^[a-z0-9_.-]+$').hasMatch(user)) {
        setState(() => _error = 'Letters, numbers, dot, dash or underscore only.');
        return;
      }
      if (_pin.text.length < 4) {
        setState(() => _error = 'Set a PIN of at least 4 digits.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(staffRepositoryProvider);
      if (_isNew) {
        await repo.create(
          name: _name.text,
          username: _username.text,
          role: _role,
          pin: _pin.text,
        );
      } else {
        await repo.update(
          id: widget.existing!.id,
          name: _name.text,
          role: _role,
          active: _active,
        );
      }
      navigator.pop();
      return;
    } catch (err) {
      setState(() {
        _busy = false;
        _error = _friendly(err);
      });
    }
  }

  Future<void> _resetPin() async {
    final staff = widget.existing;
    if (staff == null) return;

    final pin = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPinDialog(name: staff.name),
    );
    if (pin == null || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await ref
          .read(staffRepositoryProvider)
          .resetPin(staffId: staff.id, pin: pin);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = '${staff.name} can sign in with the new PIN now.';
      });
    } catch (err) {
      setState(() {
        _busy = false;
        _error = _friendly(err);
      });
    }
  }

  Future<void> _delete() async {
    final staff = widget.existing;
    if (staff == null) return;

    final ok = await confirmDestructive(
      context,
      title: 'Remove ${staff.name}?',
      message: 'They will not be able to sign in. Orders they took keep their '
          'name, so your history stays intact.',
      confirmLabel: 'Remove',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    try {
      await ref.read(staffRepositoryProvider).remove(staff.id);
      navigator.pop();
      return;
    } catch (err) {
      setState(() {
        _busy = false;
        _error = _friendly(err);
      });
    }
  }

  /// PocketBase validation blobs are unreadable; name the two that actually
  /// come up and pass anything else through.
  String _friendly(Object err) {
    final text = '$err';
    if (text.contains('username') && text.contains('unique')) {
      return 'That username is already taken.';
    }
    if (text.contains('validation_')) {
      return 'Some of those details were not accepted. Check the username.';
    }
    final match = RegExp(r'message: ([^,}]+)').firstMatch(text);
    return match?.group(1)?.trim() ?? text;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final me = ref.watch(currentStaffProvider);
    final isMe = widget.existing?.id == me?.id;
    final iAmOwner = me?.role.isOwner ?? false;

    return FormDialog(
      title: _isNew ? 'Add someone' : widget.existing!.name,
      busy: _busy,
      error: _error,
      onSave: _save,
      onDelete: (_isNew || isMe || !iAmOwner) ? null : _delete,
      children: [
        if (_notice != null) ...[
          MessageBanner(tone: BannerTone.success, message: _notice!),
          const SizedBox(height: Space.md),
        ],
        AppField(
          label: 'Name',
          controller: _name,
          hint: 'Rahim Uddin',
          autofocus: true,
          enabled: !_busy,
        ),
        const SizedBox(height: Space.md),
        AppField(
          label: 'Username',
          controller: _username,
          hint: 'rahim',
          // A username is what past shifts are filed under; changing it later
          // would quietly detach someone from their own history.
          enabled: _isNew && !_busy,
          helper: _isNew
              ? 'Short and easy to type at a busy terminal.'
              : 'Usernames cannot be changed.',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.-]')),
          ],
        ),
        if (_isNew) ...[
          const SizedBox(height: Space.md),
          AppField(
            label: 'PIN',
            controller: _pin,
            obscure: true,
            maxLength: 8,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helper: 'At least 4 digits. They can be given a new one any time.',
          ),
        ],
        const SizedBox(height: Space.lg),
        Text('What they can do',
            style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final role in StaffRole.values)
              // Only an owner may hand out ownership.
              if (role != StaffRole.owner || iAmOwner)
                _RoleOption(
                  role: role,
                  selected: _role == role,
                  onTap: _busy ? null : () => setState(() => _role = role),
                ),
          ],
        ),
        if (!_isNew) ...[
          const SizedBox(height: Space.lg),
          FormSwitch(
            label: 'Can sign in',
            description: _active
                ? 'Their account works normally.'
                : 'Switched off, without deleting anything.',
            value: _active,
            onChanged: (_busy || isMe) ? null : (v) => setState(() => _active = v),
          ),
          if (isMe)
            Text('You cannot switch off your own account.',
                style: AppType.small.copyWith(color: p.textTertiary)),
          const SizedBox(height: Space.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _resetPin,
              icon: const Icon(Icons.password_rounded, size: 17),
              label: const Text('Give them a new PIN'),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final StaffRole role;
  final bool selected;
  final VoidCallback? onTap;

  static String _describe(StaffRole role) => switch (role) {
        StaffRole.owner => 'Everything, including staff and ownership.',
        StaffRole.manager => 'Menu, tables, settings and reports.',
        StaffRole.waiter => 'Takes orders on the floor.',
        StaffRole.cashier => 'Takes orders and settles bills.',
        StaffRole.kitchen => 'Sees the pass and nothing else.',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: selected ? p.brandSubtle : p.surfaceSunken,
        borderRadius: Radii.medium,
        child: InkWell(
          borderRadius: Radii.medium,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.medium,
              border: Border.all(
                color: selected ? p.brand : p.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: selected ? p.brand : p.textTertiary,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.label,
                          style: AppType.bodyStrong.copyWith(
                            color: selected ? p.brand : p.textPrimary,
                          )),
                      Text(_describe(role),
                          style: AppType.small.copyWith(color: p.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetPinDialog extends StatefulWidget {
  const _ResetPinDialog({required this.name});

  final String name;

  @override
  State<_ResetPinDialog> createState() => _ResetPinDialogState();
}

class _ResetPinDialogState extends State<_ResetPinDialog> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New PIN for ${widget.name}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: AppField(
          label: 'PIN',
          controller: _pin,
          obscure: true,
          autofocus: true,
          maxLength: 8,
          errorText: _error,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          helper: 'Tell them in person, not over the pass.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_pin.text.length < 4) {
              setState(() => _error = 'At least 4 digits.');
              return;
            }
            Navigator.of(context).pop(_pin.text);
          },
          child: const Text('Set PIN'),
        ),
      ],
    );
  }
}
