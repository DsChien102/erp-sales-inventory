import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

/// In-memory session snapshot — implements shared current-user/tenant contracts.
final class IamSession
    implements ICurrentUser, ICurrentTenant, IPrincipalSnapshot {
  String? _userId;
  String? _tenantId;
  String? _role;
  Set<String> _permissions = {};

  @override
  String? get userId => _userId;

  @override
  String? get tenantId => _tenantId;

  @override
  String? get role => _role;

  Set<String> get permissions => Set.unmodifiable(_permissions);

  @override
  bool hasPermission(String code) =>
      _role == 'owner' || _permissions.contains(code);

  void apply(PrincipalAccessDto dto) {
    _userId = dto.userId;
    _tenantId = dto.tenantId;
    _role = dto.role;
    _permissions = dto.permissions.toSet();
  }

  void clear() {
    _userId = null;
    _tenantId = null;
    _role = null;
    _permissions = {};
  }

  SessionDto toDto({String? email}) {
    return SessionDto(
      isAuthenticated: _userId != null,
      userId: _userId,
      email: email,
      tenantId: _tenantId,
      role: _role,
      permissions: _permissions.toList(growable: false),
    );
  }
}
