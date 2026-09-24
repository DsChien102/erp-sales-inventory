import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../mappers/accessible_tenant_ui_mapper.dart';
import 'tenant_context_state.dart';

/// Applies [TenantContextDto.permissions] to navigation/session after switch.
typedef TenantContextPermissionsApplier = void Function(TenantContextDto context);

final class TenantContextCubit extends Cubit<TenantContextState> {
  TenantContextCubit({
    required IIamModule iamModule,
    String userDisplayName = '',
    TenantContextState? initialState,
    TenantContextPermissionsApplier? applyPermissions,
    Stream<String>? tenantAccessRevoked,
    void Function(String code)? onIdentityRevoked,
  }) : _iamModule = iamModule,
       _applyPermissions = applyPermissions,
       _onIdentityRevoked = onIdentityRevoked,
       super(
         initialState ?? TenantContextState(userDisplayName: userDisplayName),
       ) {
    _revokedSubscription = (tenantAccessRevoked ?? TenantAccessRevokedSignal.stream)
        .listen(_onTenantAccessRevoked);
  }

  final IIamModule _iamModule;
  final TenantContextPermissionsApplier? _applyPermissions;
  final void Function(String code)? _onIdentityRevoked;
  late final StreamSubscription<String> _revokedSubscription;

  void _onTenantAccessRevoked(String code) {
    if (isClosed) return;
    if (code == TenantAccessRevokedSignal.platformUserSuspended) {
      // Tài khoản bị chặn ở mọi tổ chức → shell đăng xuất.
      _onIdentityRevoked?.call(code);
      return;
    }
    if (state.status != TenantContextLoadStatus.ready) return;
    bootstrap();
  }

  @override
  Future<void> close() {
    // Do not await cancel(): broadcast cancel can hang under flutter_test fake async.
    _revokedSubscription.cancel();
    return super.close();
  }

  Future<void> bootstrap() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: TenantContextLoadStatus.loading,
        clearContextFailure: true,
        clearBlockedErrorCode: true,
        clearSelectorFailure: true,
        clearSwitchFailure: true,
        clearEmptyState: true,
        openSelectorRequested: false,
      ),
    );

    try {
      final context = await _iamModule.executeQueryAsync<TenantContextDto>(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );
      if (isClosed) return;

      await loadAccessibleTenants();
      if (isClosed) return;

      _emitResolvedContext(context);
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TenantContextLoadStatus.failure,
          contextFailure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  Future<void> loadAccessibleTenants() async {
    if (isClosed) return;
    final keepStatus = state.status;
    emit(
      state.copyWith(
        tenantsLoading: true,
        clearSelectorFailure: true,
      ),
    );

    try {
      final dtos = await _iamModule.executeQueryAsync<List<AccessibleTenantDto>>(
        ListAccessibleTenantsQuery(),
      );
      if (isClosed) return;

      emit(
        state.copyWith(
          status: keepStatus,
          tenants: AccessibleTenantUiMapper.fromList(dtos),
          tenantsLoading: false,
          clearSelectorFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      // Selector load failure must not demote a valid dashboard context.
      // Clear stale rows so selector shows loadError/retry instead of old data.
      emit(
        state.copyWith(
          status: keepStatus,
          tenants: const [],
          tenantsLoading: false,
          selectorFailure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  /// Returns `true` when switch succeeds. Confirmation is UI-only.
  Future<bool> switchTo(String tenantId) async {
    if (isClosed) return false;
    emit(
      state.copyWith(
        isSwitching: true,
        clearSwitchFailure: true,
      ),
    );

    try {
      final context = await _iamModule.executeCommandAsync<TenantContextDto>(
        SwitchTenantContextCommand(targetTenantId: tenantId),
      );
      if (isClosed) return false;

      await loadAccessibleTenants();
      if (isClosed) return false;

      _applyPermissions?.call(context);

      emit(
        state.copyWith(
          status: TenantContextLoadStatus.ready,
          current: context,
          branchDisplayName: context.tenantName,
          isSwitching: false,
          openSelectorRequested: false,
          clearEmptyState: true,
          clearSwitchFailure: true,
          clearContextFailure: true,
          clearBlockedErrorCode: true,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) return false;
      final failure = _mapFailure(error);
      emit(
        state.copyWith(
          isSwitching: false,
          switchFailure: failure,
        ),
      );

      if (_shouldReloadTenantsAfterSwitchFailure(failure)) {
        await loadAccessibleTenants();
      }
      return false;
    }
  }

  void consumeOpenSelectorRequest() {
    if (isClosed || !state.openSelectorRequested) return;
    emit(state.copyWith(openSelectorRequested: false));
  }

  void requestOpenSelector() {
    if (isClosed) return;
    emit(state.copyWith(openSelectorRequested: true));
  }

  /// Empty-state for the selector sheet: loadError wins over empty list.
  OrganizationEmptyStateType? get selectorEmptyStateType {
    if (state.selectorFailure != null) {
      return OrganizationEmptyStateType.loadError;
    }
    if (state.tenants.isEmpty) {
      return OrganizationEmptyStateType.noAuthorizedOrganizations;
    }
    return null;
  }

  /// Retry load for selector sheet. Returns tenants on success, `null` on fail.
  Future<List<SelectOrganizationItemUiModel>?> retryLoadAccessibleTenants() async {
    await loadAccessibleTenants();
    if (isClosed) return null;
    if (state.selectorFailure != null) return null;
    return state.tenants;
  }

  IamUiFailure _mapFailure(Object error) {
    if (error is ApplicationException) {
      final trimmed = error.message.trim();
      // Preserve stable switch codes (e.g. TENANT_ACCESS_DENIED) that are not
      // yet in IamBlockedCodes catalog.
      if (trimmed.isNotEmpty &&
          trimmed == trimmed.toUpperCase() &&
          trimmed.contains('_')) {
        return IamUiFailure(code: trimmed, message: trimmed);
      }
    }
    return IamUiFailureMapper.from(error);
  }

  bool _shouldReloadTenantsAfterSwitchFailure(IamUiFailure failure) {
    return failure.code == IamBlockedCodes.tenantSuspended ||
        failure.code == IamBlockedCodes.tenantClosed;
  }

  void _emitResolvedContext(TenantContextDto context) {
    if (context.status == TenantContextStatus.valid) {
      _applyPermissions?.call(context);
    }
    switch (context.status) {
      case TenantContextStatus.valid:
        emit(
          state.copyWith(
            status: TenantContextLoadStatus.ready,
            current: context,
            branchDisplayName: context.tenantName,
            clearEmptyState: true,
            clearContextFailure: true,
            clearBlockedErrorCode: true,
            openSelectorRequested: false,
          ),
        );
        break;
      case TenantContextStatus.none:
        emit(
          state.copyWith(
            status: TenantContextLoadStatus.blocked,
            current: context,
            clearBranchDisplayName: true,
            emptyStateType: OrganizationEmptyStateType.noAuthorizedOrganizations,
            openSelectorRequested: true,
            clearContextFailure: true,
            clearBlockedErrorCode: true,
          ),
        );
        break;
      case TenantContextStatus.invalidated:
        if (context.blockedErrorCode == IamBlockedCodes.platformUserSuspended ||
            context.invalidationReason ==
                TenantContextInvalidationReason.identityInactive) {
          // Tài khoản bị tạm ngừng: không cho vào app, đăng xuất luôn.
          _onIdentityRevoked?.call(IamBlockedCodes.platformUserSuspended);
        }
        final inaccessible =
            context.invalidationReason ==
                TenantContextInvalidationReason.tenantSuspended ||
            context.invalidationReason ==
                TenantContextInvalidationReason.tenantClosed ||
            context.invalidationReason ==
                TenantContextInvalidationReason.identityInactive ||
            context.blockedErrorCode == IamBlockedCodes.tenantSuspended ||
            context.blockedErrorCode == IamBlockedCodes.tenantClosed ||
            context.blockedErrorCode == IamBlockedCodes.platformUserSuspended;
        emit(
          state.copyWith(
            status: TenantContextLoadStatus.blocked,
            current: context,
            clearBranchDisplayName: true,
            blockedErrorCode: context.blockedErrorCode,
            emptyStateType: inaccessible
                ? OrganizationEmptyStateType.inaccessible
                : OrganizationEmptyStateType.noAuthorizedOrganizations,
            suspendedOrgName: context.tenantName,
            openSelectorRequested: true,
            clearContextFailure: true,
          ),
        );
        break;
    }
  }
}
