import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Adds IAM profile login audit after credential sign-in succeeds.
final class LoginAuditAuthenticator implements IAuthenticator {
  LoginAuditAuthenticator({
    required IAuthenticator inner,
    required SupabaseSchemaRpcClient rpcClient,
  }) : _inner = inner,
       _rpcClient = rpcClient;

  final IAuthenticator _inner;
  final SupabaseSchemaRpcClient _rpcClient;

  @override
  String? get currentEmail => _inner.currentEmail;

  @override
  String? get currentUserId => _inner.currentUserId;

  @override
  AuthSessionState get sessionState => _inner.sessionState;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _inner.signIn(email: email, password: password);
    try {
      await _rpcClient.callScalar<Object?>('assert_my_platform_access');
    } on RpcException catch (error) {
      if (error.message.toUpperCase().contains(
        IamBlockedCodes.platformUserSuspended,
      )) {
        await _inner.signOut();
        throw const IamBlockedException(IamBlockedCodes.platformUserSuspended);
      }
      // Other failures do not block sign-in; server RPCs still deny suspended users.
    }
    try {
      await _rpcClient.callScalar<Object?>('record_my_platform_login');
    } on RpcException {
      // Last-login capture must not block an otherwise valid auth session.
    }
  }

  @override
  Future<void> signOut() {
    return _inner.signOut();
  }
}
