// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'platform_onboarding_state.dart';

/// Owner search + tenant onboarding submit via [IIamModule] (EP-01 US-03).
final class PlatformOnboardingCubit extends Cubit<PlatformOnboardingState> {
  PlatformOnboardingCubit({required IIamModule iamModule})
    : _iamModule = iamModule,
      super(const PlatformOnboardingState());

  final IIamModule _iamModule;

  Future<void> searchOwners(String query) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PlatformOnboardingLoadStatus.searching,
        clearError: true,
      ),
    );
    try {
      final page = await _iamModule.executeQueryAsync<CursorPageDto<PlatformUserSummaryDto>>(
        SearchPlatformUsersQuery(
          query: query.trim().isEmpty ? null : query.trim(),
          status: PlatformUserStatus.active,
        ),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformOnboardingLoadStatus.idle,
          searchResults: page.items,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformOnboardingLoadStatus.failure,
          errorMessage: e.toString(),
          searchResults: const [],
        ),
      );
    }
  }

  Future<TenantOnboardingResultDto?> submit({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? organizationDisplayName,
    String? contactEmail,
    String? contactPhone,
    String? contactAddressText,
    String? provinceCode,
    String? communeCode,
    String? legalName,
    String? taxCode,
    String? registeredAddressText,
  }) async {
    if (isClosed) return null;
    emit(
      state.copyWith(
        status: PlatformOnboardingLoadStatus.submitting,
        clearError: true,
        clearResult: true,
      ),
    );
    try {
      final result = await _iamModule.executeCommandAsync<TenantOnboardingResultDto>(
        CreateTenantOnboardingCommand(
          owner: owner,
          organizationName: organizationName,
          organizationDisplayName: organizationDisplayName,
          contactEmail: contactEmail,
          contactPhone: contactPhone,
          contactAddressText: contactAddressText,
          provinceCode: provinceCode,
          communeCode: communeCode,
          legalName: legalName,
          taxCode: taxCode,
          registeredAddressText: registeredAddressText,
          idempotencyKey: idempotencyKey,
        ),
      );
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: PlatformOnboardingLoadStatus.success,
          result: result,
          clearError: true,
        ),
      );
      return result;
    } on ApplicationException catch (e) {
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: PlatformOnboardingLoadStatus.failure,
          errorMessage: e.message,
        ),
      );
      return null;
    } catch (e) {
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: PlatformOnboardingLoadStatus.failure,
          errorMessage: e.toString(),
        ),
      );
      return null;
    }
  }
}
