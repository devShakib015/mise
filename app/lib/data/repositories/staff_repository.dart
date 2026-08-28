import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../live.dart';
import '../models/staff.dart';
import 'menu_repository.dart' show pbProvider;

final staffListProvider = StreamProvider<List<Staff>>(
  (ref) => liveCollection(ref, 'staff', Staff.fromRecord, sort: 'role,name'),
);

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(ref.watch(pbProvider)),
);

class StaffRepository {
  const StaffRepository(this._pb);

  final PocketBase _pb;

  /// Creates an account. A PIN is only set here — changing it later goes
  /// through [resetPin], because PocketBase demands the old one otherwise.
  Future<void> create({
    required String name,
    required String username,
    required StaffRole role,
    required String pin,
    String email = '',
  }) async {
    await _pb.collection('staff').create(body: {
      'name': name.trim(),
      'username': username.trim().toLowerCase(),
      'role': role.name,
      'active': true,
      'password': pin,
      'passwordConfirm': pin,
      if (email.trim().isNotEmpty) 'email': email.trim(),
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required StaffRole role,
    required bool active,
  }) async {
    await _pb.collection('staff').update(id, body: {
      'name': name.trim(),
      'role': role.name,
      'active': active,
    });
  }

  /// Resets someone else's forgotten PIN.
  ///
  /// Goes through a server route rather than a plain update: PocketBase
  /// requires `oldPassword` to change an auth record's password, which nobody
  /// has when the PIN is the thing that was forgotten.
  Future<void> resetPin({required String staffId, required String pin}) async {
    await _pb.send<Map<String, dynamic>>(
      '/api/app/staff/reset-pin',
      method: 'POST',
      body: {'staff_id': staffId, 'pin': pin},
    );
  }

  Future<void> remove(String id) => _pb.collection('staff').delete(id);
}
