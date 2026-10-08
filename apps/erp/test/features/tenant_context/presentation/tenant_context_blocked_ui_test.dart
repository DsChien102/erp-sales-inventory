import 'package:erp/features/iam/presentation.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

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

  test(
    'bootstrap identityInactive → inaccessible + platformUserSuspended + sign-out once',
    () async {
      final cubit = SessionController(
        iamModule: _PlatformUserSuspendedIamModule(),
      );

      await cubit.bootstrap();

      expect(cubit.state.emptyStateType, OrganizationEmptyStateType.inaccessible);
      expect(cubit.state.blockedErrorCode, IamBlockedCodes.platformUserSuspended);
      expect(cubit.state.identityRevoked, isTrue);

      await cubit.close();
    },
  );
}

/// Returns invalidated identityInactive + PLATFORM_USER_SUSPENDED on bootstrap.
final class _PlatformUserSuspendedIamModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetTenantContextQuery) {
      return TenantContextDto(
            status: TenantContextStatus.invalidated,
            tenantId: 't1',
            tenantName: 'Thú y Minh Phát',
            invalidationReason: TenantContextInvalidationReason.identityInactive,
            blockedErrorCode: IamBlockedCodes.platformUserSuspended,
          )
          as TResult;
    }
    if (query is ListAccessibleTenantsQuery) {
      return const <AccessibleTenantDto>[] as TResult;
    }
    throw UnimplementedError(query.runtimeType.toString());
  }
}
