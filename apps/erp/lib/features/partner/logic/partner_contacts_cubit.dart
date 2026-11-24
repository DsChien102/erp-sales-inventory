import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/partner_error_codes.dart';
import '../data/partner_repository.dart';
import 'partner_contacts_state.dart';
import 'partner_error_messages.dart';
import 'package:erp/core/errors/app_exception.dart';

final class PartnerContactsCubit extends Cubit<PartnerContactsState> {
  PartnerContactsCubit({required PartnerRepository repository})
    : _repository = repository,
      super(const PartnerContactsInitial());

  final PartnerRepository _repository;

  static const _loadFallback = 'Không tải được danh sách người liên hệ. Vui lòng thử lại.';
  static const _actionFallback = 'Không thể cập nhật người liên hệ. Vui lòng thử lại.';

  Future<void> loadContacts(String organizationPartnerId) async {
    emit(const PartnerContactsLoading());
    try {
      final result = await _repository.getDetail(organizationPartnerId);
      emit(PartnerContactsLoaded(organization: result));
    } catch (e) {
      emit(PartnerContactsError(
        partnerErrorMessage(e, fallback: _loadFallback),
        isNoPermission: e is AppException && e.code == PartnerErrorCodes.noPermission,
      ));
    }
  }

  void searchContacts(String query) {
    final currentState = state;
    if (currentState is PartnerContactsLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  Future<void> setPrimaryContact(String personPartnerId) async {
    final currentState = state;
    if (currentState is! PartnerContactsLoaded) return;

    emit(currentState.copyWith(isActionLoading: true));
    try {
      await _repository.updateContact(
        organizationPartnerId: currentState.organization.partnerId,
        personPartnerId: personPartnerId,
        isPrimary: true,
      );

      // Reload contacts list
      await loadContacts(currentState.organization.partnerId);
    } catch (e) {
      emit(currentState.copyWith(
        isActionLoading: false,
        actionError: partnerErrorMessage(e, fallback: _actionFallback),
      ));
    }
  }

  Future<void> removeContact(String personPartnerId) async {
    final currentState = state;
    if (currentState is! PartnerContactsLoaded) return;

    emit(currentState.copyWith(isActionLoading: true));
    try {
      await _repository.removeContact(
        organizationPartnerId: currentState.organization.partnerId,
        personPartnerId: personPartnerId,
      );

      // Reload contacts list
      await loadContacts(currentState.organization.partnerId);
    } catch (e) {
      emit(currentState.copyWith(
        isActionLoading: false,
        actionError: partnerErrorMessage(e, fallback: _actionFallback),
      ));
    }
  }

  Future<void> addExistingContacts(List<String> personPartnerIds) async {
    final currentState = state;
    if (currentState is! PartnerContactsLoaded) return;

    emit(currentState.copyWith(isActionLoading: true));
    try {
      for (final personPartnerId in personPartnerIds) {
        await _repository.addContact(
          organizationPartnerId: currentState.organization.partnerId,
          personPartnerId: personPartnerId,
        );
      }

      await loadContacts(currentState.organization.partnerId);
    } catch (e) {
      emit(currentState.copyWith(
        isActionLoading: false,
        actionError: partnerErrorMessage(e, fallback: _actionFallback),
      ));
    }
  }
}
