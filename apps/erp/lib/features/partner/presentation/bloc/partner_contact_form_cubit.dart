import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_contact_form_state.dart';

final class PartnerContactFormCubit extends Cubit<PartnerContactFormState> {
  PartnerContactFormCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  })  : _partnerModule = partnerModule,
        _executionContext = executionContext,
        super(const PartnerContactFormState());

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  Future<void> loadPersonDetail(String personPartnerId) async {
    emit(state.copyWith(status: PartnerContactFormStatus.loadingPersonDetail));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final result = await _partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(
          tenantId: tenantId,
          partnerId: personPartnerId,
        ),
      );
      emit(state.copyWith(
        status: PartnerContactFormStatus.initial,
        personDetail: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.error,
        errorMessage: e.toString(),
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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      if (!ignoreDuplicate) {
        final matches = await _partnerModule.executeQueryAsync(
          CheckDuplicatePartnersQuery(
            tenantId: tenantId,
            phone: phone.trim().isNotEmpty ? phone.trim() : null,
            email: email != null && email.trim().isNotEmpty ? email.trim() : null,
            name: fullName.trim().isNotEmpty ? fullName.trim() : null,
          ),
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

      await _partnerModule.executeCommandAsync(
        AddOrganizationContactCommand(
          tenantId: tenantId,
          actorId: actorId,
          organizationPartnerId: organizationPartnerId,
          newPersonProfile: profileInput,
          contactRole: contactRole != null && contactRole.trim().isNotEmpty
              ? contactRole.trim()
              : null,
          isPrimary: isPrimary,
        ),
      );

      emit(state.copyWith(status: PartnerContactFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.error,
        errorMessage: e.toString(),
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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      // Single command: update contact link + linked Person profile.
      // Do NOT call UpdatePartnerProfileCommand here — that requires
      // partner.update + transaction roles and breaks contact-only Persons
      // (BR-04 / PersonOrOrganizationProfileExclusiveRule).
      await _partnerModule.executeCommandAsync(
        UpdateOrganizationContactCommand(
          tenantId: tenantId,
          actorId: actorId,
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
        ),
      );

      emit(state.copyWith(status: PartnerContactFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.error,
        errorMessage: e.toString(),
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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      await _partnerModule.executeCommandAsync(
        AddOrganizationContactCommand(
          tenantId: tenantId,
          actorId: actorId,
          organizationPartnerId: organizationPartnerId,
          personPartnerId: personPartnerId,
          contactRole: contactRole != null && contactRole.trim().isNotEmpty
              ? contactRole.trim()
              : null,
          isPrimary: isPrimary,
        ),
      );

      emit(state.copyWith(status: PartnerContactFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: PartnerContactFormStatus.error,
        errorMessage: e.toString(),
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
