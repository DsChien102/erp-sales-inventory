import 'package:erp/core/validation/tax_code.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../data/organization_repository.dart';
import 'iam_load_status.dart';
import 'iam_ui_failure.dart';
import 'iam_ui_failure_mapper.dart';
import 'organization_profile_form_input.dart';
import 'organization_profile_state.dart';

final class OrganizationProfileCubit extends Cubit<OrganizationProfileState> {
  OrganizationProfileCubit({required OrganizationRepository organizationRepository})
    : _organizationRepository = organizationRepository,
      super(const OrganizationProfileState());

  final OrganizationRepository _organizationRepository;

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
      final tenant = await _organizationRepository.getTenant();
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
      final updated = await _organizationRepository.updateProfile(
        displayName: displayName,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        contactAddressText: contactAddressText,
        provinceCode: input.provinceCode,
        communeCode: input.communeCode,
        expectedVersion: tenant.version,
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
      final result = await _organizationRepository.upsertLegalProfile(
        legalEntityType: input.legalEntityType.trim(),
        legalName: input.legalName.trim(),
        taxCode: normalizeTaxCode(input.taxCode),
        registeredAddressText: input.registeredAddressText?.trim(),
        provinceCode: input.provinceCode,
        communeCode: input.communeCode,
        expectedVersion: tenant.version,
        allowDuplicateTaxCode: allowDuplicateTaxCode,
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

      await _reloadAfterLegalSuccess(tenantVersion: result.tenantVersion);
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

  Future<void> _reloadAfterLegalSuccess({required int tenantVersion}) async {
    try {
      final refreshed = await _organizationRepository.getTenant();
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
      final current = state.tenant;
      emit(
        state.copyWith(
          isSubmittingLegal: false,
          tenant: current?.copyWith(version: tenantVersion),
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
        final refreshed = await _organizationRepository.getTenant();
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
    if (!isValidTaxCode(input.taxCode)) {
      return const IamUiFailure(
        code: IamBlockedCodes.validationError,
        message: taxCodeFormatMessage,
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
