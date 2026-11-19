import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/models/session_snapshot.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/core/session/session_store.dart';

import '../../../core/session/fake_session_repository.dart';

/// [SessionController] đã đăng nhập sẵn (hoặc chưa), có tổ chức / cửa hàng / vai trò / quyền.
SessionController testSessionController({
  String tenantId = 'org-001',
  String userId = 'u1',
  String role = 'staff',
  bool isOwner = false,
  List<String> permissions = const [],
  bool signedIn = true,
  String? activeStoreId,
  String? activeStoreCode,
  String? activeStoreDisplayName,
  String? correlationId,
}) {
  final store = SessionStore();
  if (signedIn) {
    store.apply(
      SessionPrincipal(
        userId: userId,
        tenantId: tenantId,
        activeStoreId: activeStoreId,
        activeStoreCode: activeStoreCode,
        activeStoreDisplayName: activeStoreDisplayName,
        role: role,
        isOwner: isOwner,
        permissions: permissions,
      ),
    );
  }
  return SessionController(
    repository: FakeSessionRepository(),
    store: store,
    correlationId: correlationId,
    initialState: SessionState(
      authStatus: signedIn ? AuthStatus.signedIn : AuthStatus.signedOut,
      userId: signedIn ? userId : null,
    ),
  );
}

/// Dựng [SessionController] từ một [SessionSnapshot] mẫu.
SessionController sessionFromSnapshot(SessionSnapshot snapshot) {
  return testSessionController(
    signedIn: snapshot.isAuthenticated,
    userId: (snapshot.userId == null || snapshot.userId!.isEmpty) ? 'u1' : snapshot.userId!,
    tenantId: snapshot.tenantId ?? '',
    role: (snapshot.role == null || snapshot.role!.isEmpty) ? 'staff' : snapshot.role!,
    isOwner: snapshot.isOwner,
    permissions: snapshot.permissions,
  );
}
