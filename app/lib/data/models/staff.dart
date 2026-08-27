import 'package:pocketbase/pocketbase.dart';

/// What a staff member is allowed to do, and which shell they land in.
enum StaffRole {
  owner,
  manager,
  waiter,
  cashier,
  kitchen;

  static StaffRole parse(String raw) => StaffRole.values.firstWhere(
        (r) => r.name == raw,
        orElse: () => StaffRole.waiter,
      );

  String get label => switch (this) {
        StaffRole.owner => 'Owner',
        StaffRole.manager => 'Manager',
        StaffRole.waiter => 'Waiter',
        StaffRole.cashier => 'Cashier',
        StaffRole.kitchen => 'Kitchen',
      };

  /// Owners and managers configure the system; everyone else only operates it.
  bool get canManage => this == StaffRole.owner || this == StaffRole.manager;

  /// Only an owner may create or remove other staff at the top level.
  bool get isOwner => this == StaffRole.owner;

  /// Which of the three shells this role opens into.
  AppShell get shell => switch (this) {
        StaffRole.owner || StaffRole.manager => AppShell.manager,
        StaffRole.waiter || StaffRole.cashier => AppShell.pos,
        StaffRole.kitchen => AppShell.kitchen,
      };
}

/// One app, three faces. The signed-in role picks which one you get.
enum AppShell { pos, kitchen, manager }

class Staff {
  const Staff({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.active,
    this.email = '',
    this.avatar = '',
  });

  final String id;
  final String name;
  final String username;
  final StaffRole role;
  final bool active;
  final String email;
  final String avatar;

  factory Staff.fromRecord(RecordModel r) => Staff(
        id: r.id,
        name: r.getStringValue('name'),
        username: r.getStringValue('username'),
        role: StaffRole.parse(r.getStringValue('role')),
        active: r.getBoolValue('active'),
        email: r.getStringValue('email'),
        avatar: r.getStringValue('avatar'),
      );

  /// First letters of the first two words, for avatar fallbacks.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((s) => s[0].toUpperCase()).join();
  }
}
