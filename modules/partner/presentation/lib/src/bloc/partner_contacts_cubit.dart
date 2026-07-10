import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_contacts_state.dart';

final class PartnerContactsCubit extends Cubit<PartnerContactsState> {
  PartnerContactsCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  })  : _partnerModule = partnerModule,
        _executionContext = executionContext,
        super(const PartnerContactsInitial());

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  Future<void> loadContacts(String organizationPartnerId) async {
    emit(const PartnerContactsLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final result = await _partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(
          tenantId: tenantId,
          partnerId: organizationPartnerId,
        ),
      );
      emit(PartnerContactsLoaded(organization: result));
    } catch (e) {
      final errorStr = e.toString();
      final isNoPermission = errorStr.contains('NO_PERMISSION') ||
          errorStr.contains('permission denied');
      emit(PartnerContactsError(errorStr, isNoPermission: isNoPermission));
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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      
      await _partnerModule.executeCommandAsync(
        UpdateOrganizationContactCommand(
          tenantId: tenantId,
          actorId: actorId,
          organizationPartnerId: currentState.organization.partnerId,
          personPartnerId: personPartnerId,
          isPrimary: true,
        ),
      );
      
      // Reload contacts list
      await loadContacts(currentState.organization.partnerId);
    } catch (e) {
      emit(currentState.copyWith(
        isActionLoading: false,
        actionError: e.toString(),
      ));
    }
  }

  Future<void> removeContact(String personPartnerId) async {
    final currentState = state;
    if (currentState is! PartnerContactsLoaded) return;

    emit(currentState.copyWith(isActionLoading: true));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      
      await _partnerModule.executeCommandAsync(
        RemoveOrganizationContactCommand(
          tenantId: tenantId,
          actorId: actorId,
          organizationPartnerId: currentState.organization.partnerId,
          personPartnerId: personPartnerId,
        ),
      );
      
      // Reload contacts list
      await loadContacts(currentState.organization.partnerId);
    } catch (e) {
      emit(currentState.copyWith(
        isActionLoading: false,
        actionError: e.toString(),
      ));
    }
  }

  Future<void> addExistingContacts(List<String> personPartnerIds) async {
    final currentState = state;
    if (currentState is! PartnerContactsLoaded) return;

    emit(currentState.copyWith(isActionLoading: true));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      
      for (final personPartnerId in personPartnerIds) {
        await _partnerModule.executeCommandAsync(
          AddOrganizationContactCommand(
            tenantId: tenantId,
            actorId: actorId,
            organizationPartnerId: currentState.organization.partnerId,
            personPartnerId: personPartnerId,
          ),
        );
      }
      
      await loadContacts(currentState.organization.partnerId);
    } catch (e) {
      emit(currentState.copyWith(
        isActionLoading: false,
        actionError: e.toString(),
      ));
    }
  }
}
