import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_cubit.dart';
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  test('copyWith keeps blockedErrorCode when clearing context failure', () {
    const state = TenantContextState(userDisplayName: '');
    final blocked = state.copyWith(
      status: TenantContextLoadStatus.blocked,
      blockedErrorCode: IamBlockedCodes.tenantClosed,
      clearContextFailure: true,
    );
    expect(blocked.blockedErrorCode, IamBlockedCodes.tenantClosed);
  });

  test('copyWith can clear branch display name', () {
    const state = TenantContextState(userDisplayName: '', branchDisplayName: 'Vua');
    expect(state.copyWith(clearBranchDisplayName: true).branchDisplayName, isNull);
  });

  test('becameBlocked listenWhen ignores loading hop from ready', () {
    // Mirrors dashboard BlocListener listenWhen (5g).
    bool listenWhen(TenantContextState previous, TenantContextState current) =>
        !previous.isBlocked && current.isBlocked;

    const ready = TenantContextState(
      userDisplayName: '',
      status: TenantContextLoadStatus.ready,
    );
    const loading = TenantContextState(
      userDisplayName: '',
      status: TenantContextLoadStatus.loading,
    );
    const blocked = TenantContextState(
      userDisplayName: '',
      status: TenantContextLoadStatus.blocked,
    );

    // Old condition (ready → blocked) fails on the real bootstrap path:
    expect(ready.status == TenantContextLoadStatus.ready && loading.isBlocked, isFalse);
    expect(loading.status == TenantContextLoadStatus.ready && blocked.isBlocked, isFalse);

    // New condition fires once when entering blocked via loading:
    expect(listenWhen(ready, loading), isFalse);
    expect(listenWhen(loading, blocked), isTrue);
    expect(listenWhen(blocked, blocked), isFalse);
  });

  test(
    'bootstrap identityInactive → inaccessible + platformUserSuspended + sign-out once',
    () async {
      final codes = <String>[];
      final cubit = TenantContextCubit(
        iamModule: _PlatformUserSuspendedIamModule(),
        onIdentityRevoked: codes.add,
      );

      await cubit.bootstrap();

      expect(cubit.state.emptyStateType, OrganizationEmptyStateType.inaccessible);
      expect(cubit.state.blockedErrorCode, IamBlockedCodes.platformUserSuspended);
      expect(codes, [IamBlockedCodes.platformUserSuspended]);

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
