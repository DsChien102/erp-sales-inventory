import 'package:c45_shared_application/application.dart';

import 'models/session_principal.dart';
import 'session_repository.dart';

/// Phiên trong bộ nhớ: người dùng, tổ chức và cửa hàng đang chọn, vai trò, quyền.
///
/// `SessionController` ghi vào đây; các module nghiệp vụ cũ đọc qua
/// `CoreExecutionContext` (xem `session_contracts.dart`).
base class SessionStore {
  SessionStore({SessionRepository? repository}) : _repository = repository;

  final SessionRepository? _repository;

  String? _userId;
  String? _tenantId;
  String? _activeStoreId;
  String? _activeStoreCode;
  String? _activeStoreDisplayName;
  String? _role;
  bool _isOwner = false;
  Set<String> _permissions = {};
  Future<void>? _refreshInFlight;

  String? get userId => _userId;

  String? get tenantId => _tenantId;

  String? get activeStoreId => _activeStoreId;

  String? get activeStoreCode => _activeStoreCode;

  String? get activeStoreDisplayName => _activeStoreDisplayName;

  String? get role => _role;

  /// Sở hữu tổ chức; độc lập với [role].
  bool get isOwner => _isOwner;

  Set<String> get permissions => Set.unmodifiable(_permissions);

  // Tạm thời (TH-01 BR-52): mọi thành viên hoạt động của tổ chức (đã có `role`)
  // có đủ quyền nghiệp vụ, giống `iam.has_permission` phía server.
  // Khi quản lý vai trò theo quyền ra đời, đổi về `isOwner || permissions.contains(code)`.
  bool hasPermission(String code) => _role != null || _permissions.contains(code);

  /// Cửa hàng đang hoạt động. Thiếu thì nạp lại từ `get_session_context` đúng một
  /// lần cho mọi lời gọi song song.
  Future<String> requireActiveStoreId() async {
    if (!_hasActiveStore) {
      await _refreshActiveStore();
    }
    final storeId = _activeStoreId;
    if (storeId == null || storeId.isEmpty) {
      throw const ApplicationException('Active store context is required.');
    }
    return storeId;
  }

  bool get _hasActiveStore {
    final storeId = _activeStoreId;
    return storeId != null && storeId.isNotEmpty;
  }

  void apply(SessionPrincipal principal) {
    _userId = principal.userId;
    _tenantId = principal.tenantId;
    _activeStoreId = principal.activeStoreId?.trim();
    _activeStoreCode = principal.activeStoreCode;
    _activeStoreDisplayName = principal.activeStoreDisplayName;
    _role = principal.role;
    _isOwner = principal.isOwner;
    _permissions = principal.permissions.toSet();
  }

  /// Gắn người dùng vừa xác thực, chưa có tổ chức.
  void applyAuthenticatedUser(String userId) {
    clear();
    _userId = userId;
  }

  void clear() {
    _userId = null;
    _tenantId = null;
    _activeStoreId = null;
    _activeStoreCode = null;
    _activeStoreDisplayName = null;
    _role = null;
    _isOwner = false;
    _permissions = {};
  }

  Future<void> _refreshActiveStore() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _doRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<void> _doRefresh() async {
    final tenantId = _tenantId?.trim();
    if (tenantId == null || tenantId.isEmpty) {
      // Đa tổ chức: không bao giờ gọi get_session_context khi chưa chọn tổ chức.
      throw const ApplicationException('Tenant context is required.');
    }
    final repository = _repository;
    final principal = repository == null ? null : await repository.getSessionContext(tenantId);
    if (principal == null) {
      throw const ApplicationException('Active store context is required.');
    }
    apply(principal);
  }
}
