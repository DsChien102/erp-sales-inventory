import 'package:flutter_bloc/flutter_bloc.dart';
import '../../mock_partner_data.dart';
import 'partner_create_state.dart';

class PartnerCreateCubit extends Cubit<PartnerCreateState> {
  final MockPartnerRepository _repository;

  PartnerCreateCubit(this._repository) : super(const PartnerCreateState());

  void updateRole(String role) => emit(state.copyWith(role: role, errorMessage: null));
  void updateProfileType(String type) => emit(state.copyWith(profileType: type, errorMessage: null));
  void updateName(String name) => emit(state.copyWith(name: name, errorMessage: null));
  void updatePhone(String phone) => emit(state.copyWith(phone: phone, errorMessage: null));
  void updateEmail(String email) => emit(state.copyWith(email: email, errorMessage: null));
  void updateAddress(String address) => emit(state.copyWith(address: address, errorMessage: null));
  void updateTaxId(String taxId) => emit(state.copyWith(taxId: taxId, errorMessage: null));
  void updateNote(String note) => emit(state.copyWith(note: note, errorMessage: null));

  Future<void> submit() async {
    // 1. Validation
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Tên đối tác không được để trống.', status: PartnerCreateStatus.error));
      return;
    }
    if (state.phone.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Số điện thoại không được để trống.', status: PartnerCreateStatus.error));
      return;
    }

    emit(state.copyWith(status: PartnerCreateStatus.loading, errorMessage: null));

    // 2. Check duplicates
    try {
      final warnings = await _repository.checkDuplicate(
        state.phone.trim(),
        state.email.trim(),
        state.taxId.trim(),
      );

      if (warnings.isNotEmpty) {
        emit(state.copyWith(
          status: PartnerCreateStatus.duplicateWarning,
          duplicateWarnings: warnings,
        ));
        return;
      }
    } catch (e) {
      emit(state.copyWith(
        status: PartnerCreateStatus.error,
        errorMessage: 'Lỗi kiểm tra trùng lặp: ${e.toString()}',
      ));
      return;
    }

    // 3. Save if no warning
    await _save();
  }

  Future<void> confirmSubmit() async {
    // Gọi khi người dùng bỏ qua cảnh báo trùng lặp
    emit(state.copyWith(status: PartnerCreateStatus.loading));
    await _save();
  }

  void cancelSubmit() {
    emit(state.copyWith(status: PartnerCreateStatus.initial));
  }

  Future<void> _save() async {
    try {
      final formData = PartnerFormData(
        role: state.role,
        type: state.profileType,
        name: state.name.trim(),
        phone: state.phone.trim(),
        email: state.email.trim(),
        address: state.address.trim(),
        taxId: state.taxId.trim(),
        note: state.note.trim(),
      );

      await _repository.savePartner(formData);

      emit(state.copyWith(status: PartnerCreateStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerCreateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
