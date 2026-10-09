import 'package:supabase/supabase.dart';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/auth/data/models/signup_input.dart';
import 'package:erp/features/iam/data/models/password_reset_result.dart';

class AuthRepository {
  AuthRepository({
    required SupabaseRpc rpc,
    required GoTrueClient auth,
  }) : _rpc = rpc,
       _auth = auth;

  final SupabaseRpc _rpc;
  final GoTrueClient _auth;

  /// Đăng nhập email/mật khẩu, kiểm tra tài khoản nền tảng, ghi nhận lần đăng nhập.
  /// Trả `userId`. Lỗi mật khẩu / email chưa xác nhận đi qua [AppException.from].
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } catch (error) {
      throw AppException.from(error);
    }

    try {
      await _rpc.call('iam', 'assert_my_platform_access');
    } on AppException catch (error) {
      if (_containsPlatformUserSuspended(error)) {
        await _auth.signOut();
        throw const AppException('PLATFORM_USER_SUSPENDED');
      }
    }

    try {
      await _rpc.call('iam', 'record_my_platform_login');
    } on AppException {
      // Ghi nhận lần đăng nhập không được chặn phiên hợp lệ.
    }

    final userId = _auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) {
      throw const AppException(AppErrorCode.authRequired);
    }
    return userId;
  }

  /// Tạo tài khoản từ lời mời.
  /// [needsVerification] khi Auth chưa trả session (xác minh email đang bật).
  Future<({String userId, bool needsVerification})> signUpFromInvitation({
    required String email,
    required String password,
    required String givenName,
    required String familyName,
    String? phone,
  }) async {
    final canonical = email.trim().toLowerCase();
    final trimmedPhone = phone?.trim();
    try {
      final response = await _auth.signUp(
        email: canonical,
        password: password,
        data: <String, dynamic>{
          'first_name': givenName,
          'last_name': familyName,
          if (trimmedPhone != null && trimmedPhone.isNotEmpty) 'phone': trimmedPhone,
        },
      );
      final user = response.user;
      final returnedEmail = (user?.email ?? '').trim().toLowerCase();
      if (user == null || returnedEmail != canonical) {
        throw const AppException(AppErrorCode.unknown);
      }
      if (_isObfuscatedExistingUser(user)) {
        throw const AppException('PLATFORM_USER_ALREADY_EXISTS');
      }
      return (userId: user.id, needsVerification: response.session == null);
    } on AppException {
      rethrow;
    } on AuthException catch (error) {
      throw _mapInvitationAuthException(error);
    } catch (_) {
      throw const AppException(AppErrorCode.unknown);
    }
  }

  /// Đăng ký cửa hàng mới. Tổ chức chỉ được tạo khi email được xác minh.
  Future<void> signUpStore({
    required SignupAccountInput account,
    required SignupStoreInput store,
  }) async {
    final email = account.email.trim().toLowerCase();
    try {
      final response = await _auth.signUp(
        email: email,
        password: account.password,
        data: <String, dynamic>{
          'profile': account.toProfileMetadata(),
          'signup_tenant': store.toMetadata(fallbackEmail: email),
        },
      );
      final user = response.user;
      if (user == null) {
        throw const AppException(AppErrorCode.unknown);
      }
      if (_isObfuscatedExistingUser(user)) {
        throw const AppException('PLATFORM_USER_ALREADY_EXISTS');
      }
    } on AppException {
      rethrow;
    } on AuthException catch (error) {
      throw _mapInvitationAuthException(error);
    } catch (_) {
      throw const AppException(AppErrorCode.unknown);
    }
  }

  /// Xác minh mã OTP đăng ký. Trả `userId` của session vừa tạo.
  Future<String> verifySignupOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.signup,
      );
      final userId = response.user?.id.trim();
      if (userId == null || userId.isEmpty) {
        throw const AppException(AppErrorCode.unknown);
      }
      return userId;
    } on AppException {
      rethrow;
    } on AuthException catch (error) {
      throw _mapSignupOtpException(error);
    } catch (_) {
      throw const AppException(AppErrorCode.unknown);
    }
  }

  Future<void> resendSignupOtp(String email) async {
    try {
      await _auth.resend(
        email: email.trim().toLowerCase(),
        type: OtpType.signup,
      );
    } on AppException {
      rethrow;
    } on AuthException catch (error) {
      throw AppException.from(error);
    } catch (_) {
      throw const AppException(AppErrorCode.unknown);
    }
  }

  bool _isObfuscatedExistingUser(User user) {
    final identities = user.identities;
    return identities != null && identities.isEmpty;
  }

  AppException _mapSignupOtpException(AuthException error) {
    final code = error.code?.trim().toLowerCase() ?? '';
    final message = error.message.toLowerCase();
    if (error.statusCode == '500' || message.contains('database error')) {
      return const AppException('SIGNUP_TENANT_FAILED');
    }
    if (code.contains('otp') ||
        code.contains('expired') ||
        code.contains('invalid') ||
        message.contains('otp') ||
        message.contains('expired') ||
        message.contains('invalid')) {
      return const AppException('OTP_INVALID');
    }
    return const AppException(AppErrorCode.unknown);
  }

  Future<PasswordResetRequestResult> requestMyPasswordReset() async {
    final email = _requireSignedInEmail();
    final row = await _rpc.firstRow('iam', 'begin_password_reset_operation');
    return PasswordResetRequestResult.fromJson(row, maskedEmail: maskEmail(email));
  }

  Future<PasswordResetRequestResult> resendMyPasswordReset(String operationId) async {
    final email = _requireSignedInEmail();
    final row = await _rpc.firstRow(
      'iam',
      'resend_password_reset_operation',
      params: {'p_operation_id': operationId},
    );
    return PasswordResetRequestResult.fromJson(row, maskedEmail: maskEmail(email));
  }

  Future<PasswordResetVerifyResult> verifyMyPasswordReset(
    String operationId,
    String code,
  ) async {
    _requireSignedIn();
    final row = await _rpc.firstRow(
      'iam',
      'verify_password_reset_code',
      params: {'p_operation_id': operationId, 'p_code': code},
    );
    return PasswordResetVerifyResult.fromJson(row);
  }

  Future<PasswordResetCompletionResult> completeMyPasswordReset(
    String operationId,
    String newPassword,
  ) async {
    _requireSignedIn();
    final current = await _rpc.firstRow(
      'iam',
      'get_password_reset_operation',
      params: {'p_operation_id': operationId},
    );
    final status = (current['status'] as String?) ?? 'pending';
    if (status != 'verified') {
      throw const AppException(AppErrorCode.stateChanged);
    }
    await _updatePassword(newPassword);
    await _signOutOtherSessions();
    await _rpc.call(
      'iam',
      'mark_password_reset_operation_completed',
      params: {'p_operation_id': operationId},
    );
    return const PasswordResetCompletionResult(
      currentSessionRotated: true,
      otherSessionsRevoked: true,
    );
  }

  Future<PasswordResetRequestResult> requestPasswordResetByEmail(String email) {
    return _publicRequest('begin_password_reset_operation_by_email', {
      'p_email': email,
    });
  }

  Future<PasswordResetRequestResult> resendPasswordResetByEmail(String operationId) {
    return _publicRequest('resend_password_reset_operation_by_email', {
      'p_operation_id': operationId,
    });
  }

  Future<PasswordResetVerifyResult> verifyPasswordResetByEmail(
    String operationId,
    String code,
  ) async {
    final row = await _rpc.firstRow(
      'iam',
      'verify_password_reset_code_by_email',
      params: {'p_operation_id': operationId, 'p_code': code},
    );
    return PasswordResetVerifyResult.fromJson(row);
  }

  Future<PasswordResetCompletionResult> completePasswordResetByEmail(
    String operationId,
    String newPassword,
  ) async {
    final row = await _rpc.firstRow(
      'iam',
      'complete_password_reset_operation_by_email',
      params: {
        'p_operation_id': operationId,
        'p_new_password': newPassword,
      },
    );
    return PasswordResetCompletionResult.fromJson(row);
  }

  Future<PasswordResetRequestResult> _publicRequest(
    String fn,
    Map<String, dynamic> params,
  ) async {
    final row = await _rpc.firstRow('iam', fn, params: params);
    return PasswordResetRequestResult.fromJson(row);
  }

  void _requireSignedIn() {
    if (_auth.currentUser == null) {
      throw const AppException(AppErrorCode.authRequired);
    }
  }

  String _requireSignedInEmail() {
    _requireSignedIn();
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw const AppException(AppErrorCode.unknown);
    }
    return email;
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AppException {
      rethrow;
    } catch (error) {
      final code = error is AuthException ? error.code?.toLowerCase() : null;
      final text = error.toString().toLowerCase();
      if (code == 'weak_password' ||
          code == 'password_too_weak' ||
          (text.contains('password') &&
              (text.contains('weak') ||
                  text.contains('short') ||
                  text.contains('policy') ||
                  text.contains('at least')))) {
        throw const AppException('PASSWORD_POLICY_VIOLATION');
      }
      throw const AppException(AppErrorCode.unknown);
    }
  }

  bool _containsPlatformUserSuspended(AppException error) {
    final blob = '${error.code} ${error.serverMessage ?? ''} ${error.cause}'.toUpperCase();
    return blob.contains('PLATFORM_USER_SUSPENDED');
  }

  AppException _mapInvitationAuthException(AuthException error) {
    const duplicateCodes = <String>{'email_exists', 'user_already_exists'};
    const validationCodes = <String>{
      'weak_password',
      'validation_failed',
      'email_address_invalid',
    };
    final code = error.code?.trim().toLowerCase();
    if (code != null && duplicateCodes.contains(code)) {
      return const AppException('PLATFORM_USER_ALREADY_EXISTS');
    }
    if (code != null && validationCodes.contains(code)) {
      return const AppException(AppErrorCode.validation);
    }
    if (code != null && code.isNotEmpty) {
      return const AppException(AppErrorCode.unknown);
    }
    final message = error.message.toLowerCase();
    if (message.contains('already') ||
        message.contains('registered') ||
        message.contains('exists')) {
      return const AppException('PLATFORM_USER_ALREADY_EXISTS');
    }
    if (message.contains('password') || message.contains('weak') || message.contains('invalid')) {
      return const AppException(AppErrorCode.validation);
    }
    return const AppException(AppErrorCode.unknown);
  }

  Future<void> _signOutOtherSessions() async {
    try {
      await _auth.signOut(scope: SignOutScope.others);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(AppErrorCode.unknown);
    }
  }
}
