import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
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
  })  : _partnerModule = partnerModule,
        _executionContext = executionContext,
        _initialPartner = initialPartner,
        super(const PartnerEditState());

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;
  final PartnerItemModel? _initialPartner;

  Future<void> loadPartner(String partnerId) async {
    emit(state.copyWith(status: PartnerEditStatus.loadingData));

    final initialPartner = _initialPartner;
    if (initialPartner != null && initialPartner.id == partnerId) {
      _applyPartnerModel(initialPartner);
      return;
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      final result = await _partnerModule.executeQueryAsync(
        SearchPartnersQuery(
          tenantId: tenantId,
          criteria: PartnerSearchCriteria(
            statuses: {
              PartnerStatus.active,
              PartnerStatus.inactive,
            },
          ),
          limit: 500,
        ),
      );

      PartnerListItemDto? match;
      for (final item in result.items) {
        if (item.id == partnerId) {
          match = item;
          break;
        }
      }
      if (match == null) {
        emit(
          state.copyWith(
            status: PartnerEditStatus.loadingDataError,
            partnerId: partnerId,
            errorMessage: 'Không tìm thấy đối tác.',
          ),
        );
        return;
      }

      _applyPartnerModel(PartnerUiMapper.toListItem(match));
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerEditStatus.loadingDataError,
          partnerId: partnerId,
          errorMessage: partnerErrorMessage(error),
        ),
      );
    }
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
        note: partner.note,
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
    if (state.phone.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Số điện thoại không được để trống.',
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

    await _save();
  }

  Future<void> confirmSubmit() async {
    emit(state.copyWith(status: PartnerEditStatus.saving));
    await _save();
  }

  void cancelSubmit() {
    emit(state.copyWith(status: PartnerEditStatus.ready));
  }

  Future<List<String>> _checkDuplicates() async {
    final tenantId = await _executionContext.requireTenantId();
    final matches = await _partnerModule.executeQueryAsync(
      CheckDuplicatePartnersQuery(
        tenantId: tenantId,
        phone: state.phone.trim(),
        email: state.email.trim().isEmpty ? null : state.email.trim(),
        taxCode: state.taxId.trim().isEmpty ? null : state.taxId.trim(),
        excludePartnerId: state.partnerId,
      ),
    );

    return matches.map(PartnerUiMapper.duplicateWarning).toList(growable: false);
  }

  Future<void> _save() async {
    emit(
      state.copyWith(
        status: PartnerEditStatus.error,
        errorMessage:
            'Chức năng cập nhật đối tác chưa khả dụng trên backend.',
      ),
    );
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
}
