import 'package:flutter_bloc/flutter_bloc.dart';
import '../../mock_partner_data.dart';
import 'partner_edit_state.dart';

class PartnerEditCubit extends Cubit<PartnerEditState> {
  final MockPartnerRepository _repository;

  PartnerEditCubit(this._repository) : super(const PartnerEditState());

  void loadPartner(String partnerId) async {
    emit(state.copyWith(status: PartnerEditStatus.loadingData));
    try {
      // Giả lập load dữ liệu từ API
      await Future.delayed(const Duration(seconds: 1));
      
      // Dữ liệu giả lập
      emit(state.copyWith(
        status: PartnerEditStatus.ready,
        partnerId: partnerId,
        role: 'Khách hàng',
        profileType: 'individual',
        name: 'Nguyễn Văn A',
        phone: '0987654321',
        email: 'nguyenvana@gmail.com',
        address: '123 Đường ABC, Quận 1, TP.HCM',
        hasChanges: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerEditStatus.loadingDataError,
        errorMessage: 'Lỗi tải dữ liệu: ${e.toString()}',
      ));
    }
  }

  void updateRole(String role) => emit(state.copyWith(role: role, hasChanges: true, errorMessage: null));
  void updateProfileType(String type) => emit(state.copyWith(profileType: type, hasChanges: true, errorMessage: null));
  void updateName(String name) => emit(state.copyWith(name: name, hasChanges: true, errorMessage: null));
  void updatePhone(String phone) => emit(state.copyWith(phone: phone, hasChanges: true, errorMessage: null));
  void updateEmail(String email) => emit(state.copyWith(email: email, hasChanges: true, errorMessage: null));
  void updateAddress(String address) => emit(state.copyWith(address: address, hasChanges: true, errorMessage: null));
  void updateTaxId(String taxId) => emit(state.copyWith(taxId: taxId, hasChanges: true, errorMessage: null));
  void updateNote(String note) => emit(state.copyWith(note: note, hasChanges: true, errorMessage: null));

  Future<void> submit() async {
    // 1. Validation
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Tên đối tác không được để trống.', status: PartnerEditStatus.error));
      return;
    }
    if (state.phone.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Số điện thoại không được để trống.', status: PartnerEditStatus.error));
      return;
    }

    emit(state.copyWith(status: PartnerEditStatus.saving, errorMessage: null));

    // 2. Check duplicates (mocking)
    try {
      final warnings = await _repository.checkDuplicate(
        state.phone.trim(),
        state.email.trim(),
        state.taxId.trim(),
      );

      // Simple mock logic: if the loaded phone hasn't changed, maybe don't warn. 
      // But for simplicity, we just use the mock repo logic which warns if phone == '0987654321'.
      // In a real app we'd exclude the current partner's ID from duplicate check.
      
      if (warnings.isNotEmpty && state.phone != '0987654321') { // hacky way to prevent duplicate on own data for mock
        emit(state.copyWith(
          status: PartnerEditStatus.duplicateWarning,
          duplicateWarnings: warnings,
        ));
        return;
      }
    } catch (e) {
      emit(state.copyWith(
        status: PartnerEditStatus.error,
        errorMessage: 'Lỗi kiểm tra trùng lặp: ${e.toString()}',
      ));
      return;
    }

    // 3. Save if no warning
    await _save();
  }

  Future<void> confirmSubmit() async {
    emit(state.copyWith(status: PartnerEditStatus.saving));
    await _save();
  }

  void cancelSubmit() {
    emit(state.copyWith(status: PartnerEditStatus.ready));
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

      emit(state.copyWith(status: PartnerEditStatus.success, hasChanges: false));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerEditStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
