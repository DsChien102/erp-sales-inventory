import 'package:gotrue/gotrue.dart';
import 'package:vet45_iam_application/application.dart';

import '../../domain/platform_user/supabase_platform_user_profile_gateway.dart';
import 'password_reset_operation_store.dart';
import 'supabase_auth_account_client.dart';

/// Real IAM self-service adapter (plan §3.3).
///
/// Composes the IAM-owned profile gateway with the Supabase Auth account
/// client: profile fields come from `iam.platform_user_profiles`, while login
/// email + verified state are read (never written) from Supabase Auth.
///
/// Password reset uses the Supabase Auth six-digit recovery OTP. Operation
/// metadata (status/timing only, never the code) is tracked via
/// [PasswordResetOperationStore]. When no store is provided the reset methods
/// fail-fast with SYSTEM_ERROR (used before the store is wired).
final class SupabasePlatformIdentitySelfServiceAdapter implements IPlatformIdentitySelfServicePort {
  SupabasePlatformIdentitySelfServiceAdapter({
    required PlatformUserProfileGateway profileGateway,
    required AuthAccountClient authClient,
    PasswordResetOperationStore? passwordResetStore,
  }) : _profileGateway = profileGateway,
       _authClient = authClient,
       _passwordResetStore = passwordResetStore;

  final PlatformUserProfileGateway _profileGateway;
  final AuthAccountClient _authClient;
  final PasswordResetOperationStore? _passwordResetStore;

  @override
  Future<MyAccountDto> getMyAccount() async {
    _requireAuthenticated();
    final profile = await _profileGateway.getMyProfile();
    return _composeAccount(profile);
  }

  @override
  Future<MyAccountDto> updateMyAccount({
    required String? avatarReference,
    required String givenName,
    required String familyName,
    required String? phone,
  }) async {
    _requireAuthenticated();
    final profile = await _profileGateway.updateMyProfile(
      avatarReference: avatarReference,
      givenName: givenName,
      familyName: familyName,
      phone: phone,
    );
    return _composeAccount(profile);
  }

  @override
  Future<PasswordResetRequestResultDto> requestPasswordReset() async {
    _requireAuthenticated();
    final store = _requireStore();
    final email = _requireEmail();
    final operation = await store.begin();
    await _guardProvider(() => _authClient.sendRecoveryOtp(email: email));
    return PasswordResetRequestResultDto(
      operationId: operation.operationId,
      maskedEmail: _maskEmail(email),
      expiresAt: operation.expiresAt,
      resendAvailableAt: operation.resendAvailableAt,
    );
  }

  @override
  Future<PasswordResetRequestResultDto> resendPasswordResetCode({
    required String operationId,
  }) async {
    _requireAuthenticated();
    final store = _requireStore();
    final email = _requireEmail();
    final current = await store.get(operationId);
    if (current.status == 'completed') {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (DateTime.now().toUtc().isBefore(current.resendAvailableAt.toUtc())) {
      throw const IamBlockedException(IamBlockedCodes.resetRateLimited);
    }
    final refreshed = await store.touchResend(operationId);
    await _guardProvider(() => _authClient.sendRecoveryOtp(email: email));
    return PasswordResetRequestResultDto(
      operationId: refreshed.operationId,
      maskedEmail: _maskEmail(email),
      expiresAt: refreshed.expiresAt,
      resendAvailableAt: refreshed.resendAvailableAt,
    );
  }

  @override
  Future<PasswordResetVerifyResultDto> verifyPasswordResetCode({
    required String operationId,
    required String code,
  }) async {
    _requireAuthenticated();
    final store = _requireStore();
    final email = _requireEmail();
    final current = await store.get(operationId);
    if (current.status == 'completed') {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (DateTime.now().toUtc().isAfter(current.expiresAt.toUtc())) {
      throw const IamBlockedException(IamBlockedCodes.resetCodeExpired);
    }
    await _guardVerify(
      () => _authClient.verifyRecoveryOtp(email: email, code: code),
    );
    await store.markVerified(operationId);
    return const PasswordResetVerifyResultDto(verified: true);
  }

  @override
  Future<PasswordResetCompletionResultDto> completePasswordReset({
    required String operationId,
    required String newPassword,
  }) async {
    _requireAuthenticated();
    final store = _requireStore();
    final current = await store.get(operationId);
    if (current.status != 'verified') {
      // Must run only after recovery verification.
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    await _guardPasswordUpdate(
      () => _authClient.updatePassword(newPassword),
    );
    // Retain the current session; revoke the others.
    await _guardSignOutOtherSessions(() => _authClient.signOutOtherSessions());
    await store.markCompleted(operationId);
    return const PasswordResetCompletionResultDto(
      currentSessionRotated: true,
      otherSessionsRevoked: true,
    );
  }

  MyAccountDto _composeAccount(PlatformUserProfileSnapshot profile) {
    return MyAccountDto(
      userId: profile.userId,
      email: _authClient.currentEmail ?? '',
      givenName: profile.givenName ?? '',
      familyName: profile.familyMiddleName ?? '',
      phone: profile.phoneNumber,
      emailVerified: _authClient.isEmailVerified,
      avatarReference: profile.avatarReference,
    );
  }

  void _requireAuthenticated() {
    if (_authClient.currentUserId == null) {
      throw const IamBlockedException(IamBlockedCodes.authenticationRequired);
    }
  }

  PasswordResetOperationStore _requireStore() {
    final store = _passwordResetStore;
    if (store == null) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    return store;
  }

  String _requireEmail() {
    final email = _authClient.currentEmail;
    if (email == null || email.isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    return email;
  }

  /// Masks the local part: `lan@gmail.com` -> `l***@gmail.com`.
  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) {
      return '***';
    }
    final local = email.substring(0, at);
    final domain = email.substring(at);
    final head = local.substring(0, 1);
    return '$head***$domain';
  }

  /// Redacts provider errors; request/resend map to a rate-limit-aware failure.
  Future<void> _guardProvider(Future<void> Function() action) async {
    try {
      await action();
    } on IamBlockedException {
      rethrow;
    } catch (error) {
      if (_isRateLimited(error)) {
        throw const IamBlockedException(IamBlockedCodes.resetRateLimited);
      }
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
  }

  Future<void> _guardVerify(Future<void> Function() action) async {
    try {
      await action();
    } on IamBlockedException {
      rethrow;
    } catch (error) {
      final code = _errorCode(error);
      final text = error.toString().toLowerCase();
      if (_isExpiredCode(code) || text.contains('expired')) {
        throw const IamBlockedException(IamBlockedCodes.resetCodeExpired);
      }
      if (_isAttemptsExceededCode(code) || _isRateLimited(error) || text.contains('too many')) {
        throw const IamBlockedException(IamBlockedCodes.resetCodeAttemptsExceeded);
      }
      if (_isInvalidOtpCode(code) || text.contains('invalid') || text.contains('otp')) {
        throw const IamBlockedException(IamBlockedCodes.resetCodeInvalid);
      }
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
  }

  Future<void> _guardPasswordUpdate(Future<void> Function() action) async {
    try {
      await action();
    } on IamBlockedException {
      rethrow;
    } catch (error) {
      final code = _errorCode(error);
      final text = error.toString().toLowerCase();
      if (_isWeakPasswordCode(code) ||
          (text.contains('password') &&
              (text.contains('weak') ||
                  text.contains('short') ||
                  text.contains('policy') ||
                  text.contains('at least')))) {
        throw const IamBlockedException(
          IamBlockedCodes.passwordPolicyViolation,
        );
      }
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
  }

  Future<void> _guardSignOutOtherSessions(Future<void> Function() action) async {
    try {
      await action();
    } on IamBlockedException {
      rethrow;
    } catch (_) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
  }

  String? _errorCode(Object error) {
    if (error is AuthException) {
      return error.code?.toLowerCase();
    }
    return null;
  }

  bool _isRateLimited(Object error) {
    final code = _errorCode(error);
    if (code == 'over_request_rate_limit' || code == 'too_many_requests') {
      return true;
    }
    final text = error.toString().toLowerCase();
    return text.contains('rate') || text.contains('429') || text.contains('too many');
  }

  bool _isInvalidOtpCode(String? code) {
    return code == 'otp_expired_or_invalid' ||
        code == 'invalid_grant' ||
        code == 'otp_invalid' ||
        code == 'invalid_otp';
  }

  bool _isExpiredCode(String? code) {
    return code == 'otp_expired' || code == 'expired_otp';
  }

  bool _isAttemptsExceededCode(String? code) {
    return code == 'too_many_attempts' ||
        code == 'otp_too_many_attempts' ||
        code == 'over_request_rate_limit';
  }

  bool _isWeakPasswordCode(String? code) {
    return code == 'weak_password' || code == 'password_too_weak';
  }
}
