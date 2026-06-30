/// Read-only principal snapshot for permission checks (implemented by IAM session).
abstract interface class IPrincipalSnapshot {
  String? get role;

  bool hasPermission(String code);
}
