import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

/// In-memory session snapshot — implements shared current-user/tenant contracts.
final class IamSession implements ICurrentUser, ICurrentTenant, IPrincipalSnapshot {
  String? _userId;
  String? _tenantId;
  String? _role;
  bool _isOwner = false;
  Set<String> _permissions = {};

  @override
  String? get userId => _userId;

  @override
  String? get tenantId => _tenantId;

  @override
  String? get role => _role;

  @override
  bool get isOwner => _isOwner;

  Set<String> get permissions => Set.unmodifiable(_permissions);

  // INTERIM (Phase 2, pre-SRS role management): any member of the active tenant
  // (i.e. `_role` resolved) has every feature permission. Mirrors the server-side
  // `iam.has_permission`, which also grants all features to active members.
  // Revert to `_isOwner || _permissions.contains(code)` when SRS Theme 1
  // role management lands (ownership is the `_isOwner` flag, not a role).
  @override
  bool hasPermission(String code) => _role != null || _permissions.contains(code);

  void apply(PrincipalAccessDto dto) {
    _userId = dto.userId;
    _tenantId = dto.tenantId;
    _role = dto.role;
    _isOwner = dto.isOwner;
    _permissions = dto.permissions.toSet();
  }

  void applyAuthenticatedUser(String userId) {
    _userId = userId;
    _tenantId = null;
    _role = null;
    _isOwner = false;
    _permissions = {};
  }

  void clear() {
    _userId = null;
    _tenantId = null;
    _role = null;
    _isOwner = false;
    _permissions = {};
  }

  SessionDto toDto({String? email}) {
    return SessionDto(
      isAuthenticated: _userId != null,
      userId: _userId,
      email: email,
      tenantId: _tenantId,
      role: _role,
      isOwner: _isOwner,
      permissions: _permissions.toList(growable: false),
    );
  }
}
