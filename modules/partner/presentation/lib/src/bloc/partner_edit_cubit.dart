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
      emit(state.copyWith(role: role, hasChanges: true, errorMessage: null));
  void updateProfileType(String type) =>
      emit(state.copyWith(profileType: type, hasChanges: true, errorMessage: null));
  void updateName(String name) =>
      emit(state.copyWith(name: name, hasChanges: true, errorMessage: null));
  void updatePhone(String phone) =>
      emit(state.copyWith(phone: phone, hasChanges: true, errorMessage: null));
  void updateEmail(String email) =>
      emit(state.copyWith(email: email, hasChanges: true, errorMessage: null));
  void updateAddress(String address) =>
      emit(state.copyWith(address: address, hasChanges: true, errorMessage: null));
  void updateTaxId(String taxId) =>
      emit(state.copyWith(taxId: taxId, hasChanges: true, errorMessage: null));
  void updateBillingName(String value) => emit(
    state.copyWith(billingName: value, hasChanges: true, errorMessage: null),
  );
  void updateBillingAddress(String value) => emit(
    state.copyWith(
      billingAddress: value,
      hasChanges: true,
      errorMessage: null,
    ),
  );
  void updateBillingEmail(String value) => emit(
    state.copyWith(
      billingEmail: value,
      hasChanges: true,
      errorMessage: null,
    ),
  );
  void updateNote(String note) =>
      emit(state.copyWith(note: note, hasChanges: true, errorMessage: null));

  Future<void> submit() async {
    if (state.name.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Tên đối tác không được để trống.',
          status: PartnerEditStatus.error,
        ),
      );
      return;
    }
    final trimmedPhone = state.phone.trim();
    if (trimmedPhone.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Số điện thoại không được để trống.',
          status: PartnerEditStatus.error,
        ),
      );
      return;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmedPhone) || trimmedPhone.length < 8 || trimmedPhone.length > 15) {
      emit(
        state.copyWith(
          errorMessage: 'Số điện thoại chỉ được chứa số và từ 8-15 ký tự.',
          status: PartnerEditStatus.error,
        ),
      );
      return;
    }

    emit(state.copyWith(status: PartnerEditStatus.saving, errorMessage: null));

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

  Future<List<String>> _checkDuplicates() async {
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

    return matches.map(PartnerUiMapper.duplicateWarning).toList(growable: false);
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
