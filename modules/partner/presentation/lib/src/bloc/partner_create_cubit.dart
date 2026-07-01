import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../mappers/partner_ui_mapper.dart';
import '../utils/partner_presentation_errors.dart';
import 'partner_create_state.dart';

class PartnerCreateCubit extends Cubit<PartnerCreateState> {
  PartnerCreateCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  })  : _partnerModule = partnerModule,
        _executionContext = executionContext,
        super(const PartnerCreateState());

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  void updateRole(String role) =>
      emit(state.copyWith(role: role, errorMessage: null));
  void updateProfileType(String type) =>
      emit(state.copyWith(profileType: type, errorMessage: null, showValidationErrors: false));
  void updateName(String name) =>
      emit(state.copyWith(name: name, errorMessage: null));
  void updatePhone(String phone) =>
      emit(state.copyWith(phone: phone, errorMessage: null));
  void updateEmail(String email) =>
      emit(state.copyWith(email: email, errorMessage: null));
  void updateAddress(String address) =>
      emit(state.copyWith(address: address, errorMessage: null));
  void updateTaxId(String taxId) =>
      emit(state.copyWith(taxId: taxId, errorMessage: null));
  void updateContactName(String contactName) =>
      emit(state.copyWith(contactName: contactName, errorMessage: null));
  void updateNote(String note) =>
      emit(state.copyWith(note: note, errorMessage: null));

  Future<void> submit() async {
    if (state.name.trim().isEmpty || state.phone.trim().isEmpty) {
      emit(
        state.copyWith(
          showValidationErrors: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: PartnerCreateStatus.loading, errorMessage: null, showValidationErrors: false));

    try {
      final warnings = await _checkDuplicates();
      if (warnings.isNotEmpty) {
        emit(
          state.copyWith(
            status: PartnerCreateStatus.duplicateWarning,
            duplicateWarnings: warnings,
          ),
        );
        return;
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerCreateStatus.error,
          errorMessage: 'Lỗi kiểm tra trùng lặp: ${partnerErrorMessage(error)}',
        ),
      );
      return;
    }

    await _save(confirmDuplicate: false);
  }

  Future<void> confirmSubmit() async {
    emit(state.copyWith(status: PartnerCreateStatus.loading));
    await _save(confirmDuplicate: true);
  }

  void cancelSubmit() {
    emit(state.copyWith(status: PartnerCreateStatus.initial));
  }

  void resetForm() {
    emit(const PartnerCreateState());
  }

  Future<List<String>> _checkDuplicates() async {
    final tenantId = await _executionContext.requireTenantId();
    final matches = await _partnerModule.executeQueryAsync(
      CheckDuplicatePartnersQuery(
        tenantId: tenantId,
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

      await _partnerModule.executeCommandAsync(
        PartnerUiMapper.toRegisterCommand(
          tenantId: tenantId,
          actorId: actorId,
          role: state.role,
          profileType: state.profileType,
          name: state.name,
          phone: state.phone,
          email: state.email,
          address: state.address,
          taxId: state.taxId,
          note: state.note,
          confirmDuplicate: confirmDuplicate,
        ),
      );

      emit(state.copyWith(status: PartnerCreateStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerCreateStatus.error,
          errorMessage: partnerErrorMessage(error),
        ),
      );
    }
  }
}
