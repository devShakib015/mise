/// Reply from `GET /api/app/status` — the one thing a device may ask a server
/// before anybody has signed in.
class ServerStatus {
  const ServerStatus({
    required this.configured,
    required this.name,
    required this.hasStaff,
  });

  /// True once a restaurant exists and setup has been completed.
  final bool configured;

  /// Venue name, so the sign-in screen can greet the right place.
  final String name;

  /// True once at least one staff account exists, which is what makes the
  /// first-run bootstrap endpoint refuse to run again.
  final bool hasStaff;

  factory ServerStatus.fromJson(Map<String, dynamic> j) => ServerStatus(
        configured: j['configured'] == true,
        name: (j['name'] ?? '').toString(),
        hasStaff: j['has_staff'] == true,
      );
}
