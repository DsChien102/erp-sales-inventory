import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../core/session/fake_session_repository.dart';

void main() {
  test('copyWith keeps blockedErrorCode when clearing context failure', () {
    const state = SessionState(userDisplayName: '');
    final blocked = state.copyWith(
      status: TenantLoadStatus.blocked,
      blockedErrorCode: IamBlockedCodes.tenantClosed,
      clearContextFailure: true,
    );
    expect(blocked.blockedErrorCode, IamBlockedCodes.tenantClosed);
  });

  test('copyWith can clear branch display name', () {
    const state = SessionState(userDisplayName: '', branchDisplayName: 'Vua');
    expect(state.copyWith(clearBranchDisplayName: true).branchDisplayName, isNull);
  });

  test('becameBlocked listenWhen ignores loading hop from ready', () {
    // Mirrors dashboard BlocListener listenWhen (5g).
    bool listenWhen(SessionState previous, SessionState current) =>
        !previous.isBlocked && current.isBlocked;

    const ready = SessionState(
      userDisplayName: '',
      status: TenantLoadStatus.ready,
    );
    const loading = SessionState(
      userDisplayName: '',
      status: TenantLoadStatus.loading,
    );
    const blocked = SessionState(
      userDisplayName: '',
      status: TenantLoadStatus.blocked,
    );

    // Old condition (ready → blocked) fails on the real bootstrap path:
    expect(ready.status == TenantLoadStatus.ready && loading.isBlocked, isFalse);
    expect(loading.status == TenantLoadStatus.ready && blocked.isBlocked, isFalse);

    // New condition fires once when entering blocked via loading:
    expect(listenWhen(ready, loading), isFalse);
    expect(listenWhen(loading, blocked), isTrue);
    expect(listenWhen(blocked, blocked), isFalse);
  });

  test('bootstrap identityInactive becomes no authorized organization', () async {
    final repository = FakeSessionRepository()
      ..overrideContext = const TenantContext(
        status: TenantContextStatus.invalidated,
        tenantId: 'org-001',
        tenantName: 'Thú y Minh Phát',
        invalidationReason: TenantContextInvalidationReason.identityInactive,
        blockedErrorCode: IamBlockedCodes.platformUserSuspended,
      );
    final cubit = SessionController(repository: repository);

    await cubit.bootstrap();

    expect(
      cubit.state.emptyStateType,
      OrganizationEmptyStateType.noAuthorizedOrganizations,
    );
    expect(cubit.state.identityRevoked, isFalse);

    await cubit.close();
  });
}
