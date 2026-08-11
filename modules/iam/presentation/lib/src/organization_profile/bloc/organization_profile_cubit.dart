import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';
import '../../shared/iam_ui_failure_mapper.dart';
import 'organization_profile_form_input.dart';
import 'organization_profile_state.dart';

final class OrganizationProfileCubit extends Cubit<OrganizationProfileState> {
  OrganizationProfileCubit({
    required IIamModule iamModule,
    required IExecutionContext executionContext,
  }) : _iamModule = iamModule,
       _executionContext = executionContext,
       super(const OrganizationProfileState());

  final IIamModule _iamModule;
  final IExecutionContext _executionContext;

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        clearFailure: true,
        clearSuccessMessage: true,
        clearDuplicate: true,
        clearPendingLegal: true,
      ),
    );
    try {
      final tenant = await _fetchTenant();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          tenant: tenant,
          clearFailure: true,
          clearSuccessMessage: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.failure,
          clearTenant: true,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  Future<bool> updateProfile(TenantProfileFormInput input) async {
    if (isClosed || state.isSubmittingProfile) return false;
    final tenant = state.tenant;
    if (tenant == null) return false;

    final displayName = input.displayName.trim();
    final contactEmail = input.contactEmail?.trim() ?? '';
    final contactPhone = input.contactPhone?.trim() ?? '';
    final contactAddressText = input.contactAddressText?.trim() ?? '';
    if (displayName.isEmpty) {
      emit(
        state.copyWith(
          failure: const IamUiFailure(
            code: IamBlockedCodes.validationError,
            message: 'Vui lòng nhập tên tổ chức.',
          ),
          clearSuccessMessage: true,
        ),
      );
      return false;
    }

    final missingContactFields = <String>[
      if (contactEmail.isEmpty) 'email liên hệ',
      if (contactPhone.isEmpty) 'số điện thoại',
      if (contactAddressText.isEmpty) 'địa chỉ liên hệ',
    ];
    if (missingContactFields.isNotEmpty) {
      emit(
        state.copyWith(
          failure: IamUiFailure(
            code: IamBlockedCodes.validationError,
            message: 'Vui lòng nhập ${_joinVietnameseList(missingContactFields)}.',
          ),
          clearSuccessMessage: true,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isSubmittingProfile: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final updated = await _iamModule.executeCommandAsync<TenantDto>(
        UpdateTenantProfileCommand(
          tenantId: tenantId,
          displayName: displayName,
          contactEmail: contactEmail,
          contactPhone: contactPhone,
          contactAddressText: contactAddressText,
          provinceCode: input.provinceCode,
          communeCode: input.communeCode,
          expectedVersion: tenant.version,
        ),
      );
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSubmittingProfile: false,
          tenant: updated,
          status: IamLoadStatus.success,
          successMessage: 'Đã lưu thay đổi',
          clearFailure: true,
        ),
      );
      return true;
    } catch (error) {
      return _handleProfileMutationError(error, isLegal: false);
    }
  }

  Future<bool> upsertLegal(
    LegalProfileFormInput input, {
    required bool allowDuplicateTaxCode,
  }) async {
    if (isClosed || state.isSubmittingLegal) return false;
    final tenant = state.tenant;
    if (tenant == null) return false;

    final validationError = _validateLegalInput(input);
    if (validationError != null) {
      emit(
        state.copyWith(
          failure: validationError,
          clearSuccessMessage: true,
          clearDuplicate: true,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isSubmittingLegal: true,
        clearFailure: true,
        clearSuccessMessage: true,
        clearDuplicate: !allowDuplicateTaxCode,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final result = await _iamModule.executeCommandAsync<UpsertLegalProfileResultDto>(
        UpsertLegalProfileCommand(
          tenantId: tenantId,
          legalEntityType: input.legalEntityType.trim(),
          legalName: input.legalName.trim(),
          taxCode: input.taxCode.trim(),
          registeredAddressText: input.registeredAddressText?.trim(),
          provinceCode: input.provinceCode,
          communeCode: input.communeCode,
          expectedVersion: tenant.version,
          allowDuplicateTaxCode: allowDuplicateTaxCode,
        ),
      );
      if (isClosed) return false;

      if (result.isWarning) {
        emit(
          state.copyWith(
            isSubmittingLegal: false,
            duplicateWarning: result.warning,
            pendingLegalInput: input,
            clearFailure: true,
            clearSuccessMessage: true,
          ),
        );
        return false;
      }

      // Refresh version then reload current legal snapshot.
      await _reloadAfterLegalSuccess(
        tenantVersion: result.tenantVersion,
      );
      return true;
    } catch (error) {
      return _handleProfileMutationError(error, isLegal: true);
    }
  }

  Future<bool> confirmDuplicateLegal() async {
    final pending = state.pendingLegalInput;
    if (pending == null) return false;
    return upsertLegal(pending, allowDuplicateTaxCode: true);
  }

  void dismissDuplicateWarning() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearDuplicate: true,
        clearPendingLegal: true,
      ),
    );
  }

  void clearFeedback() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
  }

  Future<TenantDto> _fetchTenant() async {
    final tenantId = await _executionContext.requireTenantId();
    return _iamModule.executeQueryAsync<TenantDto>(
      GetTenantQuery(tenantId: tenantId),
    );
  }

  Future<void> _reloadAfterLegalSuccess({required int tenantVersion}) async {
    try {
      final refreshed = await _fetchTenant();
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmittingLegal: false,
          tenant: refreshed,
          status: IamLoadStatus.success,
          successMessage: 'Đã lưu hồ sơ pháp lý.',
          clearFailure: true,
          clearDuplicate: true,
          clearPendingLegal: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      // Keep bumped version hint if reload fails.
      final current = state.tenant;
      emit(
        state.copyWith(
          isSubmittingLegal: false,
          tenant: current == null
              ? null
              : TenantDto(
                  tenantId: current.tenantId,
                  displayName: current.displayName,
                  status: current.status,
                  version: tenantVersion,
                  businessTimezone: current.businessTimezone,
                  baseCurrencyCode: current.baseCurrencyCode,
                  createdAt: current.createdAt,
                  updatedAt: current.updatedAt,
                  contactEmail: current.contactEmail,
                  contactPhone: current.contactPhone,
                  contactAddressText: current.contactAddressText,
                  provinceCode: current.provinceCode,
                  communeCode: current.communeCode,
                  activatedAt: current.activatedAt,
                  legalProfile: current.legalProfile,
                ),
          successMessage: 'Đã lưu hồ sơ pháp lý.',
          failure: IamUiFailureMapper.from(error),
          clearDuplicate: true,
          clearPendingLegal: true,
        ),
      );
    }
  }

  Future<bool> _handleProfileMutationError(
    Object error, {
    required bool isLegal,
  }) async {
    if (isClosed) return false;
    final failure = IamUiFailureMapper.from(error);
    if (failure.requiresReload || failure.code == IamBlockedCodes.stateChanged) {
      try {
        final refreshed = await _fetchTenant();
        if (isClosed) return false;
        emit(
          state.copyWith(
            isSubmittingProfile: isLegal ? state.isSubmittingProfile : false,
            isSubmittingLegal: isLegal ? false : state.isSubmittingLegal,
            status: IamLoadStatus.success,
            tenant: refreshed,
            failure: failure,
            clearSuccessMessage: true,
            clearDuplicate: true,
            clearPendingLegal: true,
          ),
        );
        return false;
      } catch (_) {
        // Fall through.
      }
    }
    if (isClosed) return false;
    emit(
      state.copyWith(
        isSubmittingProfile: isLegal ? state.isSubmittingProfile : false,
        isSubmittingLegal: isLegal ? false : state.isSubmittingLegal,
        failure: failure,
        clearSuccessMessage: true,
      ),
    );
    return false;
  }

  IamUiFailure? _validateLegalInput(LegalProfileFormInput input) {
    final type = LegalEntityTypeCodes.fromCode(input.legalEntityType.trim());
    if (type == null) {
      return const IamUiFailure(
        code: IamBlockedCodes.validationError,
        message: 'Vui lòng chọn loại chủ thể.',
      );
    }
    if (input.legalName.trim().isEmpty) {
      return const IamUiFailure(
        code: IamBlockedCodes.validationError,
        message: 'Vui lòng nhập tên pháp lý.',
      );
    }
    final digits = input.taxCode.replaceAll(RegExp(r'\D'), '');
    final expected = switch (type) {
      LegalEntityType.enterprise => 10,
      LegalEntityType.householdBusiness => 12,
    };
    if (digits.length != expected || digits != input.taxCode.trim()) {
      return IamUiFailure(
        code: IamBlockedCodes.validationError,
        message: type == LegalEntityType.enterprise
            ? 'Mã số thuế doanh nghiệp phải đúng 10 chữ số.'
            : 'Mã số thuế hộ kinh doanh phải đúng 12 chữ số.',
      );
    }
    return null;
  }

  String _joinVietnameseList(List<String> values) {
    if (values.length <= 1) return values.single;
    if (values.length == 2) return '${values.first} và ${values.last}';
    return '${values.sublist(0, values.length - 1).join(', ')} và ${values.last}';
  }
}
