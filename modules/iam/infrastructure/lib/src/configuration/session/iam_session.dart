import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

/// In-memory session snapshot — implements shared current-user/tenant contracts.
final class IamSession
    implements
        IIamSessionPort,
        ICurrentUser,
        ICurrentTenant,
        IPrincipalSnapshot,
        IActiveStoreContext {
  String? _userId;
  String? _tenantId;
  String? _activeStoreId;
  String? _role;
  bool _isOwner = false;
  Set<String> _permissions = {};

  @override
  String? get userId => _userId;

  @override
  String? get tenantId => _tenantId;

  @override
  String? get activeStoreId => _activeStoreId;

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

  @override
  Future<String> requireActiveStoreId() async {
    final storeId = _activeStoreId?.trim();
    if (storeId == null || storeId.isEmpty) {
      throw ApplicationException('Active store context is required.');
    }
    return storeId;
  }

  @override
  SessionDto get snapshot => toDto();

  @override
  void apply(PrincipalAccessDto dto) {
    _userId = dto.userId;
    _tenantId = dto.tenantId;
    _activeStoreId = dto.activeStoreId?.trim();
    _role = dto.role;
    _isOwner = dto.isOwner;
    _permissions = dto.permissions.toSet();
  }

  @override
  void applyAuthenticatedUser(String userId) {
    _userId = userId;
    _tenantId = null;
    _activeStoreId = null;
    _role = null;
    _isOwner = false;
    _permissions = {};
  }

  @override
  void clear() {
    _userId = null;
    _tenantId = null;
    _activeStoreId = null;
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
      activeStoreId: _activeStoreId,
      role: _role,
      isOwner: _isOwner,
      permissions: _permissions.toList(growable: false),
    );
  }
}
