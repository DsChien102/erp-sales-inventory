/// Read-only principal snapshot for permission checks (implemented by IAM session).
abstract interface class IPrincipalSnapshot {
  String? get role;

  /// True when the active membership owns the tenant (independent of [role]).
  bool get isOwner;

  bool hasPermission(String code);
}
