import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_repository.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:erp/features/auth/data/models/signup_input.dart';
import 'package:erp/features/iam/data/account_repository.dart';
import 'package:erp/features/iam/data/models/my_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';

import '../../../core/session/fake_session_repository.dart';

SupabaseRpc testRpc() {
  return SupabaseRpc(
    SupabaseClient(
      'http://127.0.0.1',
      'anon',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ),
  );
}

class _MockAuth extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockSession extends Mock implements Session {}

/// `signIn` / `signUpFromInvitation` ghi nhận lời gọi và có thể ném lỗi cố định.
class ScriptedAuthRepository extends AuthRepository {
  ScriptedAuthRepository({
    this.signInError,
    this.signUpError,
    this.userId = 'user-1',
    this.needsVerification = false,
    List<String>? log,
  }) : _log = log,
       super(rpc: testRpc(), auth: _unusedAuth);

  static final GoTrueClient _unusedAuth = _MockAuth();

  final Object? signInError;
  final Object? signUpError;
  final String userId;
  final bool needsVerification;
  final List<String>? _log;

  final signIns = <({String email, String password})>[];
  final signUps = <({String email, String givenName, String familyName, String password})>[];
  final storeSignUps = <SignupStoreInput>[];
  final otpCodes = <String>[];
  final resentEmails = <String>[];
  final updatedPasswords = <String>[];
  Object? verifyError;
  Object? resendError;
  Object? updatePasswordError;

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    signIns.add((email: email, password: password));
    _log?.add('signIn');
    if (signInError != null) throw signInError!;
    return userId;
  }

  @override
  Future<({String userId, bool needsVerification})> signUpFromInvitation({
    required String email,
    required String password,
    required String givenName,
    required String familyName,
    String? phone,
  }) async {
    signUps.add((
      email: email,
      givenName: givenName,
      familyName: familyName,
      password: password,
    ));
    _log?.add('signUp');
    if (signUpError != null) throw signUpError!;
    return (userId: userId, needsVerification: needsVerification);
  }

  @override
  Future<void> signUpStore({
    required SignupAccountInput account,
    required SignupStoreInput store,
  }) async {
    storeSignUps.add(store);
    _log?.add('signUpStore');
    if (signUpError != null) throw signUpError!;
  }

  @override
  Future<String> verifySignupOtp({
    required String email,
    required String code,
  }) async {
    otpCodes.add(code);
    if (verifyError != null) throw verifyError!;
    return userId;
  }

  @override
  Future<void> resendSignupOtp(String email) async {
    resentEmails.add(email);
    if (resendError != null) throw resendError!;
    if (signUpError != null) throw signUpError!;
  }

  @override
  Future<void> updatePassword(String password) async {
    updatedPasswords.add(password);
    if (updatePasswordError != null) throw updatePasswordError!;
  }
}

class ScriptedAccountRepository extends AccountRepository {
  ScriptedAccountRepository({List<String>? log})
    : _log = log,
      super(rpc: testRpc(), auth: _MockAuth());

  final List<String>? _log;
  int updates = 0;

  @override
  Future<MyAccount> updateMyAccount({
    String? avatarReference,
    required String givenName,
    required String familyName,
    String? phone,
  }) async {
    updates += 1;
    _log?.add('updateAccount');
    return MyAccount(
      userId: 'user-1',
      email: 'invitee@example.com',
      givenName: givenName,
      familyName: familyName,
      phone: phone,
      emailVerified: true,
    );
  }
}

/// Phiên đăng nhập giả. [authenticated] false khiến `readSession()` trả chưa đăng nhập.
SessionController loginSession({
  bool authenticated = true,
  String? email,
  SessionRepository? repository,
  IamSession? iamSession,
  List<String>? log,
}) {
  final auth = _MockAuth();
  final user = _MockUser();
  when(() => user.id).thenReturn('user-1');
  when(() => user.email).thenReturn(email);
  when(() => auth.currentUser).thenReturn(authenticated ? user : null);
  final session = _MockSession();
  when(() => session.isExpired).thenReturn(false);
  when(() => session.user).thenReturn(user);
  when(() => auth.currentSession).thenReturn(authenticated ? session : null);
  when(() => auth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
  when(() => auth.signOut()).thenAnswer((_) async {
    log?.add('signOut');
  });
  return SessionController(
    repository: repository ?? FakeSessionRepository(),
    auth: auth,
    iamSession: iamSession ?? IamSession(),
  );
}
