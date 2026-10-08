import 'package:supabase/supabase.dart';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/models/password_reset_result.dart';

class AuthRepository {
  AuthRepository({
    required SupabaseRpc rpc,
    required GoTrueClient auth,
  }) : _rpc = rpc,
       _auth = auth;

  final SupabaseRpc _rpc;
  final GoTrueClient _auth;

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
