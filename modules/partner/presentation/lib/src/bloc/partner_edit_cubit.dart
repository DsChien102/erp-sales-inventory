import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../mappers/partner_ui_mapper.dart';
import '../utils/partner_presentation_errors.dart';
import 'partner_edit_state.dart';
import 'partner_list_state.dart';

class PartnerEditCubit extends Cubit<PartnerEditState> {
  PartnerEditCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
    PartnerItemModel? initialPartner,
  }) : _partnerModule = partnerModule,
       _executionContext = executionContext,
       _initialPartner = initialPartner,
       super(const PartnerEditState());

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;
  final PartnerItemModel? _initialPartner;

  Future<void> loadPartner(String partnerId) async {
    emit(state.copyWith(status: PartnerEditStatus.loadingData));

    try {
      final tenantId = await _executionContext.requireTenantId();
      final detail = await _partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(
          tenantId: tenantId,
          partnerId: partnerId,
        ),
      );

      if (detail == null) {
        emit(
          state.copyWith(
            status: PartnerEditStatus.loadingDataError,
            partnerId: partnerId,
            errorMessage: 'Không tìm thấy đối tác.',
          ),
        );
        return;
      }

      _applyDetail(detail);
    } catch (error) {
      final initialPartner = _initialPartner;
      if (initialPartner != null && initialPartner.id == partnerId) {
        _applyPartnerModel(initialPartner);
        return;
      }

      emit(
        state.copyWith(
          status: PartnerEditStatus.loadingDataError,
          partnerId: partnerId,
          errorMessage: partnerErrorMessage(error),
        ),
      );
    }
  }

  void _applyDetail(PartnerDetailDto detail) {
    emit(
      state.copyWith(
        status: PartnerEditStatus.ready,
        partnerId: detail.id,
        role: PartnerUiMapper.toUiRole(detail.roles),
        profileType: PartnerUiMapper.toUiProfileType(detail.entityType),
        name: detail.displayName,
        phone: detail.phone,
        email: detail.email ?? '',
        address: detail.address ?? '',
        taxId: detail.taxCode ?? '',
        billingName: detail.invoiceName ?? '',
        billingAddress: detail.invoiceAddress ?? '',
        billingEmail: detail.invoiceEmail ?? '',
        note: detail.note ?? '',
        expectedVersion: detail.version,
        createdBy: detail.createdBy,
        createdAt: detail.createdAt,
        statusKey: detail.status.name,
        hasChanges: false,
        errorMessage: null,
      ),
    );
  }

  void _applyPartnerModel(PartnerItemModel partner) {
    emit(
      state.copyWith(
        status: PartnerEditStatus.ready,
        partnerId: partner.id,
        role: _uiRoleFromLabel(partner.role),
        profileType: _uiProfileTypeFromLabel(partner.profileType),
        name: partner.name,
        phone: partner.phone,
        email: partner.email,
        address: partner.address,
        taxId: partner.taxId,
        billingName: partner.billingName,
        billingAddress: partner.billingAddress,
        billingEmail: partner.billingEmail,
        note: partner.note,
        expectedVersion: partner.version,
        createdBy: partner.creator,
        statusKey: _statusKeyFromLabel(partner.status),
        hasChanges: false,
        errorMessage: null,
      ),
    );
  }

  void updateRole(String role) =>
      emit(state.copyWith(role: role, hasChanges: true, errorMessage: null, showValidationErrors: false));
  void updateProfileType(String type) =>
      emit(state.copyWith(profileType: type, hasChanges: true, errorMessage: null, showValidationErrors: false));
  void updateName(String name) =>
      emit(state.copyWith(name: name, hasChanges: true, errorMessage: null, showValidationErrors: false));
  void updatePhone(String phone) =>
      emit(state.copyWith(phone: phone, hasChanges: true, errorMessage: null, showValidationErrors: false));
  void updateEmail(String email) =>
      emit(state.copyWith(email: email, hasChanges: true, errorMessage: null, showValidationErrors: false));
  void updateAddress(String address) =>
      emit(state.copyWith(address: address, hasChanges: true, errorMessage: null, showValidationErrors: false));
  void updateTaxId(String taxId) =>
      emit(state.copyWith(taxId: taxId, hasChanges: true, errorMessage: null, showValidationErrors: false));
  void updateBillingName(String value) => emit(
    state.copyWith(billingName: value, hasChanges: true, errorMessage: null, showValidationErrors: false),
  );
  void updateBillingAddress(String value) => emit(
    state.copyWith(
      billingAddress: value,
      hasChanges: true,
      errorMessage: null,
      showValidationErrors: false,
    ),
  );
  void updateBillingEmail(String value) => emit(
    state.copyWith(
      billingEmail: value,
      hasChanges: true,
      errorMessage: null,
      showValidationErrors: false,
    ),
  );
  void updateNote(String note) =>
      emit(state.copyWith(note: note, hasChanges: true, errorMessage: null, showValidationErrors: false));

  bool _isPhoneValid(String p) {
    if (p.trim().isEmpty) return false;
    final trimmed = p.trim();
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) return false;
    return trimmed.length >= 8 && trimmed.length <= 15;
  }

  bool _isEmailValid(String e) {
    if (e.trim().isEmpty) return true;
    return RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$").hasMatch(e.trim());
  }

  bool _isTaxIdValid(String t) {
    if (t.trim().isEmpty) return true;
    final trimmed = t.trim();
    return RegExp(r'^[0-9A-Za-z]{8,16}$').hasMatch(trimmed);
  }

  Future<void> submit() async {
    if (state.name.trim().isEmpty ||
        !_isPhoneValid(state.phone) ||
        !_isEmailValid(state.email) ||
        !_isTaxIdValid(state.taxId) ||
        !_isEmailValid(state.billingEmail)) {
      emit(
        state.copyWith(
          showValidationErrors: true,
          errorMessage: 'Thông tin nhập vào chưa hợp lệ. Vui lòng kiểm tra lại.',
          status: PartnerEditStatus.error,
        ),
      );
      return;
    }

    emit(state.copyWith(status: PartnerEditStatus.saving, errorMessage: null, showValidationErrors: false));

    try {
      final warnings = await _checkDuplicates();
      if (warnings.isNotEmpty) {
        emit(
          state.copyWith(
            status: PartnerEditStatus.duplicateWarning,
            duplicateWarnings: warnings,
          ),
        );
        return;
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerEditStatus.error,
          errorMessage: 'Lỗi kiểm tra trùng lặp: ${partnerErrorMessage(error)}',
        ),
      );
      return;
    }

    await _save(confirmDuplicate: false);
  }

  Future<void> confirmSubmit() async {
    emit(state.copyWith(status: PartnerEditStatus.saving));
    await _save(confirmDuplicate: true);
  }

  void cancelSubmit() {
    emit(state.copyWith(status: PartnerEditStatus.ready));
  }

  Future<List<PartnerDuplicateMatchDto>> _checkDuplicates() async {
    final tenantId = await _executionContext.requireTenantId();
    final matches = await _partnerModule.executeQueryAsync(
      CheckDuplicatePartnersForUpdateQuery(
        tenantId: tenantId,
        excludePartnerId: state.partnerId,
        phone: state.phone.trim(),
        email: state.email.trim().isEmpty ? null : state.email.trim(),
        taxCode: state.taxId.trim().isEmpty ? null : state.taxId.trim(),
      ),
    );

    return matches.toList(growable: false);
  }

  Future<void> _save({required bool confirmDuplicate}) async {
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      final result = await _partnerModule.executeCommandAsync(
        PartnerUiMapper.toUpdateCommand(
          tenantId: tenantId,
          actorId: actorId,
          state: state,
          confirmDuplicate: confirmDuplicate,
        ),
      );

      emit(
        state.copyWith(
          status: PartnerEditStatus.success,
          expectedVersion: result.version,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerEditStatus.error,
          errorMessage: partnerErrorMessage(error),
        ),
      );
    }
  }

  static String _uiRoleFromLabel(String role) {
    return switch (role) {
      'Nhà cung cấp' => 'supplier',
      'Khách hàng & NCC' => 'both',
      _ => 'customer',
    };
  }

  static String _uiProfileTypeFromLabel(String profileType) {
    return switch (profileType) {
      'Công ty' => 'company',
      'Hộ kinh doanh' => 'household',
      _ => 'individual',
    };
  }

  static String _statusKeyFromLabel(String status) {
    return switch (status) {
      'Ngừng hoạt động' => 'inactive',
      _ => 'active',
    };
  }
}
