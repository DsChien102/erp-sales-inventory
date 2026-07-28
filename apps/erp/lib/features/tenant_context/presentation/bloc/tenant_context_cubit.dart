import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../mappers/accessible_tenant_ui_mapper.dart';
import 'tenant_context_state.dart';

final class TenantContextCubit extends Cubit<TenantContextState> {
  TenantContextCubit({
    required IIamModule iamModule,
    required String userDisplayName,
    TenantContextState? initialState,
  }) : _iamModule = iamModule,
       super(
         initialState ?? TenantContextState(userDisplayName: userDisplayName),
       );

  final IIamModule _iamModule;

  Future<void> bootstrap() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: TenantContextLoadStatus.loading,
        clearError: true,
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
    } on ApplicationException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TenantContextLoadStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TenantContextLoadStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadAccessibleTenants() async {
    if (isClosed) return;
    emit(state.copyWith(tenantsLoading: true, clearError: true));

    try {
      final dtos = await _iamModule.executeQueryAsync<List<AccessibleTenantDto>>(
        ListAccessibleTenantsQuery(),
      );
      if (isClosed) return;

      emit(
        state.copyWith(
          tenants: AccessibleTenantUiMapper.fromList(dtos),
          tenantsLoading: false,
        ),
      );
    } on ApplicationException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          tenantsLoading: false,
          status: TenantContextLoadStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          tenantsLoading: false,
          status: TenantContextLoadStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Returns `true` when switch succeeds. Confirmation is UI-only.
  Future<bool> switchTo(String tenantId) async {
    if (isClosed) return false;
    emit(state.copyWith(isSwitching: true, clearError: true));

    try {
      final context = await _iamModule.executeCommandAsync<TenantContextDto>(
        SwitchTenantContextCommand(targetTenantId: tenantId),
      );
      if (isClosed) return false;

      await loadAccessibleTenants();
      if (isClosed) return false;

      emit(
        state.copyWith(
          status: TenantContextLoadStatus.ready,
          current: context,
          branchDisplayName: context.tenantName,
          isSwitching: false,
          openSelectorRequested: false,
          clearEmptyState: true,
          clearError: true,
        ),
      );
      return true;
    } on ApplicationException catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSwitching: false,
          errorMessage: e.message,
        ),
      );
      return false;
    } on ValidationException catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSwitching: false,
          errorMessage: e.message,
        ),
      );
      return false;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSwitching: false,
          errorMessage: e.toString(),
        ),
      );
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

  void _emitResolvedContext(TenantContextDto context) {
    switch (context.status) {
      case TenantContextStatus.valid:
        emit(
          state.copyWith(
            status: TenantContextLoadStatus.ready,
            current: context,
            branchDisplayName: context.tenantName,
            clearEmptyState: true,
            clearError: true,
            openSelectorRequested: false,
          ),
        );
        break;
      case TenantContextStatus.none:
        emit(
          state.copyWith(
            status: TenantContextLoadStatus.blocked,
            current: context,
            branchDisplayName: null,
            emptyStateType: OrganizationEmptyStateType.noAuthorizedOrganizations,
            openSelectorRequested: true,
            clearError: true,
          ),
        );
        break;
      case TenantContextStatus.invalidated:
        final inaccessible =
            context.invalidationReason == TenantContextInvalidationReason.tenantSuspended ||
            context.invalidationReason == TenantContextInvalidationReason.tenantClosed ||
            context.blockedErrorCode == 'TENANT_SUSPENDED' ||
            context.blockedErrorCode == 'TENANT_CLOSED';
        emit(
          state.copyWith(
            status: TenantContextLoadStatus.blocked,
            current: context,
            branchDisplayName: null,
            blockedErrorCode: context.blockedErrorCode,
            emptyStateType: inaccessible
                ? OrganizationEmptyStateType.inaccessible
                : OrganizationEmptyStateType.noAuthorizedOrganizations,
            suspendedOrgName: context.tenantName,
            openSelectorRequested: true,
            clearError: true,
          ),
        );
        break;
    }
  }
}
