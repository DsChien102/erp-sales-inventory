/// Read-only access to the authenticated user, when present.
abstract interface class ICurrentUser {
  String? get userId;
}
