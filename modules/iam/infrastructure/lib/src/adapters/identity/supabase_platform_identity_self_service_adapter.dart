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
    // The RPC generates the code, stores only its hash, and enqueues the code
    // email via the outbox transient channel. No Supabase Auth OTP is issued.
    final operation = await store.begin();
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
    // Rate-limit + status checks (and the fresh code email) are owned by the RPC.
    final refreshed = await store.touchResend(operationId);
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
    // The RPC compares the code against the stored hash and marks verified.
    final verified = await store.verifyCode(operationId, code.trim());
    return PasswordResetVerifyResultDto(verified: verified);
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

  bool _isWeakPasswordCode(String? code) {
    return code == 'weak_password' || code == 'password_too_weak';
  }
}
