import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:erp/features/iam/presentation.dart';

import 'invitation_acceptance_state.dart';

final class InvitationAcceptanceCubit extends Cubit<InvitationAcceptanceState> {
  InvitationAcceptanceCubit({
    required IIamModule iamModule,
    required IdempotencyKeyFactory keyFactory,
  }) : _iamModule = iamModule,
       _keyFactory = keyFactory,
       super(const InvitationAcceptanceState());

  final IIamModule _iamModule;
  final IdempotencyKeyFactory _keyFactory;

  /// Opaque invitation token — never exposed via public state/getters.
  String? _token;
  String? _acceptKey;
  String? _declineKey;
  String? _registerKey;

  Future<void> inspect(String token) async {
    if (isClosed || state.isSubmitting) return;
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.blocked,
          failure: const IamUiFailure(
            code: IamBlockedCodes.invitationTokenInvalid,
            message: 'Mã lời mời không hợp lệ.',
          ),
          tokenPresent: false,
          clearInspection: true,
        ),
      );
      return;
    }

    _token = trimmed;
    emit(
      state.copyWith(
        step: InvitationAcceptanceStep.inspecting,
        tokenPresent: true,
        isSubmitting: true,
        clearFailure: true,
        clearInspection: true,
        clearAcceptedMembership: true,
        clearRegistrationResult: true,
      ),
    );

    try {
      final inspection = await _iamModule.executeQueryAsync<InvitationTokenInspectionDto>(
        InspectInvitationTokenQuery(token: trimmed),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          step: inspection.accountExists
              ? InvitationAcceptanceStep.existingAccountLogin
              : InvitationAcceptanceStep.newAccountRegistration,
          inspection: inspection,
          tokenPresent: true,
          isSubmitting: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      _handleInspectOrTerminalError(error, clearToken: true);
    }
  }

  Future<void> loginAndAccept({required String password}) async {
    if (isClosed || state.isSubmitting) return;
    final token = _token;
    final inspection = state.inspection;
    if (token == null || inspection == null) {
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.tokenEntry,
          failure: const IamUiFailure(
            code: IamBlockedCodes.invitationTokenInvalid,
            message: 'Mã lời mời không hợp lệ.',
          ),
          tokenPresent: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        step: InvitationAcceptanceStep.submitting,
        isSubmitting: true,
        clearFailure: true,
      ),
    );

    try {
      await _iamModule.executeCommandAsync(
        SignInCommand(
          email: inspection.inviteeEmail,
          password: password,
          requireTenantContext: false,
        ),
      );
      final session = await _iamModule.executeQueryAsync<SessionDto>(
        GetCurrentSessionQuery(),
      );
      if (!session.isAuthenticated || !_emailsMatch(session.email, inspection.inviteeEmail)) {
        emit(
          state.copyWith(
            step: InvitationAcceptanceStep.existingAccountLogin,
            isSubmitting: false,
            failure: const IamUiFailure(
              code: IamBlockedCodes.invitationEmailMismatch,
              message: 'Email không khớp với lời mời.',
            ),
          ),
        );
        return;
      }

      final key = _acceptKey ??= _keyFactory.next('accept-invitation');
      final membership = await _iamModule.executeCommandAsync<TenantMemberDetailDto>(
        AcceptInvitationCommand(token: token, idempotencyKey: key),
      );
      await _refreshSessionContext();
      if (isClosed) return;
      _clearSecrets();
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.accepted,
          isSubmitting: false,
          acceptedMembership: membership,
          tokenPresent: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      _handleAcceptError(error, fallbackStep: InvitationAcceptanceStep.existingAccountLogin);
    }
  }

  Future<void> acceptExistingAccount() async {
    if (isClosed || state.isSubmitting) return;
    final token = _token;
    final inspection = state.inspection;
    if (token == null || inspection == null) {
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.tokenEntry,
          failure: const IamUiFailure(
            code: IamBlockedCodes.invitationTokenInvalid,
            message: 'Mã lời mời không hợp lệ.',
          ),
          tokenPresent: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        step: InvitationAcceptanceStep.submitting,
        isSubmitting: true,
        clearFailure: true,
      ),
    );

    try {
      final key = _acceptKey ??= _keyFactory.next('accept-invitation');
      final membership = await _iamModule.executeCommandAsync<TenantMemberDetailDto>(
        AcceptInvitationCommand(token: token, idempotencyKey: key),
      );
      if (isClosed) return;
      _clearSecrets();
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.accepted,
          isSubmitting: false,
          acceptedMembership: membership,
          tokenPresent: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      _handleAcceptError(error, fallbackStep: InvitationAcceptanceStep.existingAccountLogin);
    }
  }

  Future<void> registerAndAccept({
    required String givenName,
    required String familyName,
    String? phone,
    required String password,
  }) async {
    if (isClosed || state.isSubmitting) return;
    final token = _token;
    if (token == null) {
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.tokenEntry,
          tokenPresent: false,
          failure: const IamUiFailure(
            code: IamBlockedCodes.invitationTokenInvalid,
            message: 'Mã lời mời không hợp lệ.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        step: InvitationAcceptanceStep.submitting,
        isSubmitting: true,
        clearFailure: true,
      ),
    );

    try {
      final key = _registerKey ??= _keyFactory.next('register-from-invitation');
      final result = await _iamModule.executeCommandAsync<InvitationRegistrationResultDto>(
        RegisterFromInvitationCommand(
          token: token,
          profile: InvitationRegistrationProfileInput(
            givenName: givenName.trim(),
            familyName: familyName.trim(),
            phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
          ),
          credentialProof: password,
          idempotencyKey: key,
        ),
      );
      await _refreshSessionContext();
      if (isClosed) return;
      _clearSecrets();
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.accepted,
          isSubmitting: false,
          registrationResult: result,
          acceptedMembership: result.membership,
          tokenPresent: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      final failure = IamUiFailureMapper.from(error);
      if (failure.code == IamBlockedCodes.platformUserAlreadyExists) {
        if (isClosed) return;
        emit(
          state.copyWith(
            step: InvitationAcceptanceStep.existingAccountLogin,
            isSubmitting: false,
            failure: failure,
          ),
        );
        return;
      }
      _handleAcceptError(
        error,
        fallbackStep: InvitationAcceptanceStep.newAccountRegistration,
      );
    }
  }

  Future<void> decline() async {
    if (isClosed || state.isSubmitting) return;
    final token = _token;
    if (token == null) {
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.tokenEntry,
          tokenPresent: false,
          failure: const IamUiFailure(
            code: IamBlockedCodes.invitationTokenInvalid,
            message: 'Mã lời mời không hợp lệ.',
          ),
        ),
      );
      return;
    }

    final previousStep = state.step == InvitationAcceptanceStep.submitting
        ? InvitationAcceptanceStep.existingAccountLogin
        : state.step;

    emit(
      state.copyWith(
        step: InvitationAcceptanceStep.submitting,
        isSubmitting: true,
        clearFailure: true,
      ),
    );

    try {
      final key = _declineKey ??= _keyFactory.next('decline-invitation');
      await _iamModule.executeCommandAsync(
        DeclineInvitationCommand(token: token, idempotencyKey: key),
      );
      if (isClosed) return;
      _clearSecrets();
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.declined,
          isSubmitting: false,
          tokenPresent: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      _handleAcceptError(error, fallbackStep: previousStep);
    }
  }

  void reset() {
    if (isClosed) return;
    _clearSecrets();
    emit(const InvitationAcceptanceState());
  }

  void clearFeedback() {
    if (isClosed) return;
    emit(state.copyWith(clearFailure: true));
  }

  @override
  Future<void> close() {
    _clearSecrets();
    return super.close();
  }

  Future<void> _refreshSessionContext() async {
    await _iamModule.executeQueryAsync<SessionDto>(GetCurrentSessionQuery());
    await _iamModule.executeQueryAsync<TenantContextDto>(
      GetTenantContextQuery(bootstrapFromLastSelected: true),
    );
  }

  void _clearSecrets() {
    _token = null;
    _acceptKey = null;
    _declineKey = null;
    _registerKey = null;
  }

  void _handleInspectOrTerminalError(
    Object error, {
    required bool clearToken,
  }) {
    if (isClosed) return;
    final failure = IamUiFailureMapper.from(error);
    // Inspect-time failures keep the user on the entry screen so they can
    // paste another code; the view surfaces [state.failure] as a toast. For
    // terminal codes we still strip any nuance beyond the contract code.
    final surfaced = _isTerminalTokenFailure(failure.code)
        ? _genericTokenFailure(failure)
        : failure;
    if (clearToken) {
      _clearSecrets();
    }
    emit(
      state.copyWith(
        step: InvitationAcceptanceStep.tokenEntry,
        isSubmitting: false,
        tokenPresent: !clearToken && _token != null,
        failure: surfaced,
        clearInspection: true,
      ),
    );
  }

  void _handleAcceptError(
    Object error, {
    required InvitationAcceptanceStep fallbackStep,
  }) {
    if (isClosed) return;
    final failure = IamUiFailureMapper.from(error);

    if (failure.code == IamBlockedCodes.idempotencyConflict) {
      emit(
        state.copyWith(
          step: fallbackStep,
          isSubmitting: false,
          failure: failure,
        ),
      );
      return;
    }

    if (failure.code == IamBlockedCodes.invitationEmailMismatch) {
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.existingAccountLogin,
          isSubmitting: false,
          failure: failure,
        ),
      );
      return;
    }

    if (failure.code == IamBlockedCodes.tenantSuspended) {
      // Keep token so user can retry later.
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.blocked,
          isSubmitting: false,
          tokenPresent: _token != null,
          failure: failure,
        ),
      );
      return;
    }

    if (_isTerminalTokenFailure(failure.code)) {
      _clearSecrets();
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.blocked,
          isSubmitting: false,
          tokenPresent: false,
          failure: _genericTokenFailure(failure),
          clearInspection: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        step: fallbackStep,
        isSubmitting: false,
        failure: failure,
      ),
    );
  }

  static bool _isTerminalTokenFailure(String code) {
    return code == IamBlockedCodes.invitationTokenInvalid ||
        code == IamBlockedCodes.invitationExpired ||
        code == IamBlockedCodes.invitationRevoked ||
        code == IamBlockedCodes.invitationAlreadyUsed;
  }

  /// Generic copy — do not reveal invitation existence nuances beyond contract codes.
  static IamUiFailure _genericTokenFailure(IamUiFailure failure) {
    return IamUiFailure(
      code: failure.code,
      message: failure.message,
      retryable: false,
    );
  }

  static bool _emailsMatch(String? sessionEmail, String inviteeEmail) {
    if (sessionEmail == null) return false;
    return sessionEmail.trim().toLowerCase() == inviteeEmail.trim().toLowerCase();
  }
}
