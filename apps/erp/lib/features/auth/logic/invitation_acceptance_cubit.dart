import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_ui_failure.dart';
import 'package:erp/core/iam/iam_ui_failure_mapper.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/validation/password_policy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../data/auth_repository.dart';
import '../data/invitation_acceptance_repository.dart';
import '../data/models/invitation_registration_result.dart';
import 'invitation_acceptance_state.dart';

final class InvitationAcceptanceCubit extends Cubit<InvitationAcceptanceState> {
  InvitationAcceptanceCubit({
    required InvitationAcceptanceRepository invitations,
    required AuthRepository auth,
    required SessionController session,
    required String Function(String intent) nextKey,
  }) : _invitations = invitations,
       _auth = auth,
       _session = session,
       _nextKey = nextKey,
       super(const InvitationAcceptanceState());

  final InvitationAcceptanceRepository _invitations;
  final AuthRepository _auth;
  final SessionController _session;
  final String Function(String intent) _nextKey;

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
      final inspection = await _invitations.inspect(trimmed);
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
      _emitMissingToken();
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
      final userId = await _auth.signIn(email: inspection.inviteeEmail, password: password);
      _session.applySignedInUser(userId);
      final session = _session.readSession();
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

      final key = _acceptKey ??= _nextKey('accept-invitation');
      final membership = await _invitations.accept(token, idempotencyKey: key);
      await _session.signOut();
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
      _emitMissingToken();
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
      final key = _acceptKey ??= _nextKey('accept-invitation');
      final membership = await _invitations.accept(token, idempotencyKey: key);
      await _session.signOut();
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
      _emitMissingToken();
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
      final trimmedGiven = givenName.trim();
      final trimmedFamily = familyName.trim();
      final trimmedPassword = password.trim();
      final trimmedPhone = phone?.trim();
      final key = _registerKey ??= _nextKey('register-from-invitation');
      if (key.trim().isEmpty) {
        throw const AppException(AppErrorCode.validation);
      }
      if (!PasswordPolicy.isValid(trimmedPassword) ||
          trimmedGiven.isEmpty ||
          trimmedFamily.isEmpty) {
        throw const AppException(AppErrorCode.validation);
      }

      final inspection = await _invitations.inspect(token);
      if (inspection.accountExists) {
        throw const AppException('PLATFORM_USER_ALREADY_EXISTS');
      }

      // Không có phiên đăng nhập để dọn: tài khoản được tạo đã xác minh phía server,
      // người dùng đăng nhập bằng mật khẩu vừa đặt ở màn đăng nhập.
      final membership = await _invitations.registerAndAccept(
        token: token,
        password: trimmedPassword,
        givenName: trimmedGiven,
        familyName: trimmedFamily,
        phone: trimmedPhone == null || trimmedPhone.isEmpty ? null : trimmedPhone,
        idempotencyKey: key,
      );
      if (isClosed) return;
      _clearSecrets();
      emit(
        state.copyWith(
          step: InvitationAcceptanceStep.accepted,
          isSubmitting: false,
          registrationResult: InvitationRegistrationResult(
            userId: membership.userId,
            membership: membership,
          ),
          acceptedMembership: membership,
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
      _emitMissingToken();
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
      final key = _declineKey ??= _nextKey('decline-invitation');
      if (key.trim().isEmpty) {
        throw const AppException(AppErrorCode.validation);
      }
      await _invitations.decline(token, idempotencyKey: key);
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

  void _emitMissingToken() {
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
