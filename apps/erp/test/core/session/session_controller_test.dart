import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';

class _MockAuth extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockAuthSession extends Mock implements Session {}

class _RecordingPort implements IIamSessionPort {
  final applied = <String>[];
  int clearCount = 0;

  @override
  void apply(PrincipalAccessDto context) {}

  @override
  void applyAuthenticatedUser(String userId) => applied.add(userId);

  @override
  void clear() => clearCount++;

  @override
  SessionDto get snapshot => const SessionDto(isAuthenticated: false);
}

class _ThrowingIamModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    throw Exception('sign-out failed');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError();
  }
}

void main() {
  late _MockAuth auth;
  late StreamController<AuthState> events;
  late _RecordingPort port;

  setUp(() {
    auth = _MockAuth();
    events = StreamController<AuthState>.broadcast();
    port = _RecordingPort();
    when(() => auth.onAuthStateChange).thenAnswer((_) => events.stream);
  });

  tearDown(() async {
    await events.close();
  });

  SessionController controller({
    IIamModule? iamModule,
    IamSession? iamSession,
    SessionState? initialState,
  }) {
    return SessionController(
      iamModule: iamModule ?? FakeIamModule(),
      auth: auth,
      iamSession: iamSession,
      sessionPort: port,
      initialState: initialState,
    );
  }

  test('start with a current user signs in and applies the user once', () {
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);

    final cubit = controller();
    cubit.start();

    expect(cubit.state.authStatus, AuthStatus.signedIn);
    expect(cubit.state.userId, 'user-1');
    expect(port.applied, ['user-1']);
    expect(port.clearCount, 0);

    cubit.close();
  });

  test('start without a current user signs out and clears the port', () {
    when(() => auth.currentUser).thenReturn(null);

    final cubit = controller();
    cubit.start();

    expect(cubit.state.authStatus, AuthStatus.signedOut);
    expect(port.clearCount, 1);
    expect(port.applied, isEmpty);

    cubit.close();
  });

  test('signedOut event resets state', () async {
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);

    final cubit = controller(
      initialState: const SessionState(
        authStatus: AuthStatus.signedIn,
        userId: 'user-1',
        userDisplayName: 'Lan',
        branchDisplayName: 'Cũ',
      ),
    );
    cubit.start();
    port.applied.clear();

    events.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.authStatus, AuthStatus.signedOut);
    expect(cubit.state.userId, isNull);
    expect(cubit.state.branchDisplayName, isNull);
    expect(cubit.state.userDisplayName, isEmpty);

    await cubit.close();
  });

  test('repeated signedIn for the same user does not apply again', () async {
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);
    final authSession = _MockAuthSession();
    when(() => authSession.user).thenReturn(user);

    final cubit = controller();
    cubit.start();
    expect(port.applied, ['user-1']);

    events.add(AuthState(AuthChangeEvent.signedIn, authSession));
    await Future<void>.delayed(Duration.zero);

    expect(port.applied, ['user-1']);
    expect(cubit.state.authStatus, AuthStatus.signedIn);

    await cubit.close();
  });

  test('requireTenantId without a tenant throws AUTHENTICATION_REQUIRED', () async {
    final cubit = controller(iamSession: IamSession());

    expect(
      cubit.requireTenantId,
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppErrorCode.authRequired,
        ),
      ),
    );

    await cubit.close();
  });

  test('signOut with localCleared emits signedOut', () async {
    final cubit = controller(
      initialState: const SessionState(
        authStatus: AuthStatus.signedIn,
        userId: 'user-1',
      ),
    );

    final result = await cubit.signOut();

    expect(result.localCleared, isTrue);
    expect(cubit.state.authStatus, AuthStatus.signedOut);
    expect(cubit.state.userId, isNull);

    await cubit.close();
  });

  test('signOut wraps module errors in AppException', () async {
    final cubit = controller(iamModule: _ThrowingIamModule());

    expect(cubit.signOut, throwsA(isA<AppException>()));

    await cubit.close();
  });
}
