import 'package:supabase/supabase.dart';

import 'package:vet45_iam_application/application.dart';

final class SupabaseAuthenticator implements IAuthenticator {
  SupabaseAuthenticator(this._supabase);

  final SupabaseClient _supabase;

  @override
  String? get currentEmail => _supabase.auth.currentUser?.email;

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  AuthSessionState get sessionState {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return AuthSessionState.absent;
    }
    return session.isExpired ? AuthSessionState.expired : AuthSessionState.active;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      final code = error.code?.toLowerCase();
      final msg = error.message.toLowerCase();
      if (code == 'invalid_credentials' ||
          msg.contains('invalid login') ||
          msg.contains('invalid credential')) {
        throw const IamBlockedException(
          IamBlockedCodes.invalidCredentials,
          message: 'Email hoặc mật khẩu không chính xác.',
        );
      }
      if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
        throw const IamBlockedException(
          IamBlockedCodes.identityEmailNotVerified,
          message: 'Email chưa được xác thực hoặc kích hoạt.',
        );
      }
      if (code == 'over_email_send_rate_limit' || error.statusCode == '429') {
        throw const IamBlockedException(
          IamBlockedCodes.resetRateLimited,
        );
      }
      throw IamBlockedException(
        IamBlockedCodes.systemError,
        message: error.message,
      );
    } catch (error) {
      final str = error.toString().toLowerCase();
      if (str.contains('socketexception') ||
          str.contains('connection refused') ||
          str.contains('clientexception') ||
          str.contains('failed host lookup') ||
          str.contains('network is unreachable')) {
        throw const IamBlockedException(
          IamBlockedCodes.systemError,
          message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() {
    return _supabase.auth.signOut();
  }
}
