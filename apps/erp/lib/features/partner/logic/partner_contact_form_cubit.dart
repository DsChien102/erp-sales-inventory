import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/partner_enums.dart';
import '../data/models/partner_inputs.dart';
import '../data/partner_repository.dart';
import 'partner_contact_form_state.dart';
import 'partner_error_messages.dart';

final class PartnerContactFormCubit extends Cubit<PartnerContactFormState> {
  PartnerContactFormCubit({required PartnerRepository repository})
    : _repository = repository,
      super(const PartnerContactFormState());

  final PartnerRepository _repository;

  static const _saveFallback = 'Không thể lưu người liên hệ. Vui lòng thử lại.';
  static const _saveNoPermission = 'Bạn không có quyền quản lý người liên hệ.';
  static const _loadFallback = 'Không tải được thông tin người liên hệ. Vui lòng thử lại.';

  String _saveError(Object error) => partnerErrorMessage(
    error,
    fallback: _saveFallback,
    noPermission: _saveNoPermission,
  );

  Future<void> loadPersonDetail(String personPartnerId) async {
    emit(state.copyWith(status: PartnerContactFormStatus.loadingPersonDetail));
    try {
      final result = await _repository.getDetail(personPartnerId);
      emit(state.copyWith(
        status: PartnerContactFormStatus.initial,
        personDetail: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.error,
        errorMessage: partnerErrorMessage(e, fallback: _loadFallback),
      ));
    }
  }

  Future<void> createContact({
    required String organizationPartnerId,
    required String fullName,
    required String phone,
    String? email,
    String? contactRole,
    bool isPrimary = false,
    String? note,
    bool ignoreDuplicate = false,
  }) async {
    emit(state.copyWith(
      status: PartnerContactFormStatus.submitting,
      clearDuplicate: true,
    ));
    try {
      if (!ignoreDuplicate) {
        final matches = await _repository.checkDuplicates(
          phone: phone.trim().isNotEmpty ? phone.trim() : null,
          email: email != null && email.trim().isNotEmpty ? email.trim() : null,
          name: fullName.trim().isNotEmpty ? fullName.trim() : null,
        );
        if (matches.isNotEmpty) {
          final level = matches.any(
            (match) => match.matchLevel == PartnerDuplicateMatchLevel.exact,
          )
              ? PartnerDuplicateMatchLevel.exact
              : PartnerDuplicateMatchLevel.possible;
          emit(state.copyWith(
            status: PartnerContactFormStatus.duplicate,
            duplicateMatches: matches,
            duplicateLevel: level,
          ));
          return;
        }
      }

      final profileInput = PersonProfileInput(
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email != null && email.trim().isNotEmpty ? email.trim() : null,
        note: note != null && note.trim().isNotEmpty ? note.trim() : null,
      );

      await _repository.addContact(
        organizationPartnerId: organizationPartnerId,
        newPersonProfile: profileInput,
        contactRole: contactRole != null && contactRole.trim().isNotEmpty
            ? contactRole.trim()
            : null,
        isPrimary: isPrimary,
      );

      emit(state.copyWith(status: PartnerContactFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.error,
        errorMessage: _saveError(e),
      ));
    }
  }

  Future<void> editContact({
    required String organizationPartnerId,
    required String personPartnerId,
    required String fullName,
    required String phone,
    String? email,
    String? contactRole,
    bool isPrimary = false,
    String? note,
  }) async {
    emit(state.copyWith(status: PartnerContactFormStatus.submitting));
    try {
      // Single call: update contact link + linked Person profile.
      // Do NOT call `update` here — that requires partner.update + transaction
      // roles and breaks contact-only Persons (BR-04 / PersonOrOrganizationProfileExclusiveRule).
      await _repository.updateContact(
        organizationPartnerId: organizationPartnerId,
        personPartnerId: personPartnerId,
        contactRole: contactRole != null && contactRole.trim().isNotEmpty
            ? contactRole.trim()
            : null,
        isPrimary: isPrimary,
        note: note != null && note.trim().isNotEmpty ? note.trim() : null,
        personProfile: PersonProfileInput(
          fullName: fullName.trim(),
          phone: phone.trim(),
          email: email != null && email.trim().isNotEmpty ? email.trim() : null,
          note: note != null && note.trim().isNotEmpty ? note.trim() : null,
        ),
      );

      emit(state.copyWith(status: PartnerContactFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.error,
        errorMessage: _saveError(e),
      ));
    }
  }

  Future<void> linkExistingContact({
    required String organizationPartnerId,
    required String personPartnerId,
    String? contactRole,
    bool isPrimary = false,
  }) async {
    emit(state.copyWith(status: PartnerContactFormStatus.submitting));
    try {
      await _repository.addContact(
        organizationPartnerId: organizationPartnerId,
        personPartnerId: personPartnerId,
        contactRole: contactRole != null && contactRole.trim().isNotEmpty
            ? contactRole.trim()
            : null,
        isPrimary: isPrimary,
      );

      emit(state.copyWith(status: PartnerContactFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.error,
        errorMessage: _saveError(e),
      ));
    }
  }

  void dismissDuplicate() {
    if (state.status == PartnerContactFormStatus.duplicate) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.initial,
        clearDuplicate: true,
      ));
    }
  }
}
