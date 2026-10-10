import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/features/auth/data/models/signup_input.dart';
import 'package:erp/features/auth/logic/signup_cubit.dart';
import 'package:erp/features/auth/logic/signup_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_auth.dart';

void main() {
  const account = SignupAccountInput(
    givenName: 'Lan',
    familyName: 'Nguyen',
    email: 'lan@example.com',
    password: 'password-1',
    confirmPassword: 'password-1',
  );

  const store = SignupStoreInput(
    name: 'Thú y An Phát',
    contactPhone: '0912345678',
    provinceCode: '01',
    communeCode: '00001',
    addressText: '12 Nguyen Trai',
  );

  test('password shorter than 8 characters stays on the account step', () async {
    final session = loginSession();
    final cubit = SignupCubit(auth: ScriptedAuthRepository(), session: session);

    cubit.continueToStore(
      const SignupAccountInput(
        givenName: 'Lan',
        familyName: 'Nguyen',
        email: 'lan@example.com',
        password: 'abcdefg',
        confirmPassword: 'abcdefg',
      ),
    );

    expect(cubit.state.step, SignupStep.account);
    expect(cubit.state.failure, 'Mật khẩu phải có ít nhất 8 ký tự');
    await cubit.close();
    await session.close();
  });

  test('back keeps the account already entered', () async {
    final session = loginSession();
    final cubit = SignupCubit(auth: ScriptedAuthRepository(), session: session);

    cubit.continueToStore(account);
    cubit.back();

    expect(cubit.state.step, SignupStep.account);
    expect(cubit.state.account?.email, 'lan@example.com');
    await cubit.close();
    await session.close();
  });

  test('missing address does not call signUpStore', () async {
    final auth = ScriptedAuthRepository();
    final session = loginSession();
    final cubit = SignupCubit(auth: auth, session: session);
    cubit.continueToStore(account);

    await cubit.createStore(
      const SignupStoreInput(
        name: 'Thú y An Phát',
        contactPhone: '0912345678',
        provinceCode: '01',
        communeCode: '00001',
        addressText: '   ',
      ),
    );

    expect(cubit.state.step, SignupStep.store);
    expect(cubit.state.failure, 'Vui lòng nhập địa chỉ cửa hàng');
    expect(auth.storeSignUps, isEmpty);
    await cubit.close();
    await session.close();
  });

  test('an existing email sets emailExists', () async {
    final session = loginSession();
    final cubit = SignupCubit(
      auth: ScriptedAuthRepository(
        signUpError: const AppException('PLATFORM_USER_ALREADY_EXISTS'),
      ),
      session: session,
    );
    cubit.continueToStore(account);

    await cubit.createStore(store);

    expect(cubit.state.emailExists, isTrue);
    expect(cubit.state.failure, 'Email đã được đăng ký');
    expect(cubit.state.step, SignupStep.store);
    await cubit.close();
    await session.close();
  });

  test('completeAfterVerification writes the password just entered', () async {
    final auth = ScriptedAuthRepository();
    final session = loginSession();
    final cubit = SignupCubit(auth: auth, session: session);
    cubit.continueToStore(account);
    await cubit.createStore(store);

    await cubit.completeAfterVerification('user-9');

    expect(auth.updatedPasswords, ['password-1']);
    expect(cubit.state.completed, isTrue);
    expect(cubit.state.tenantName, 'Thú y Minh Phát');
    expect(cubit.state.nameDiffers, isTrue);
    expect(cubit.state.passwordSyncFailed, isFalse);
    expect(session.state.authStatus, AuthStatus.signedIn);
    expect(session.state.userId, 'user-9');
    await cubit.close();
    await session.close();
  });

  test('completeAfterVerification still completes when the password sync fails', () async {
    final auth = ScriptedAuthRepository()..updatePasswordError = Exception('rejected');
    final session = loginSession();
    final cubit = SignupCubit(auth: auth, session: session);
    cubit.continueToStore(account);
    await cubit.createStore(
      const SignupStoreInput(
        name: 'Thú y Minh Phát',
        contactPhone: '0912345678',
        provinceCode: '01',
        communeCode: '00001',
        addressText: '12 Nguyen Trai',
      ),
    );

    await cubit.completeAfterVerification('user-9');

    expect(cubit.state.completed, isTrue);
    expect(cubit.state.passwordSyncFailed, isTrue);
    expect(cubit.state.nameDiffers, isFalse);
    await cubit.close();
    await session.close();
  });

  test('signing up again inside the cooldown opens verification with that countdown', () async {
    final auth = ScriptedAuthRepository(
      signUpError: const AppException(AppErrorCode.resendCooldown, details: {'seconds': 25}),
    );
    final session = loginSession();
    final cubit = SignupCubit(auth: auth, session: session);
    cubit.continueToStore(account);

    await cubit.createStore(store);

    expect(cubit.state.step, SignupStep.verify);
    expect(cubit.state.verifyCooldownSeconds, 25);
    expect(cubit.state.failure, isNull);
    await cubit.close();
    await session.close();
  });

  test('completeAfterVerification on a closed page still releases the signed-in hold', () async {
    final auth = ScriptedAuthRepository();
    final session = loginSession(authenticated: false);
    final cubit = SignupCubit(auth: auth, session: session);
    session.holdSignedInApply();
    await cubit.close();

    await cubit.completeAfterVerification('user-9');

    expect(session.state.authStatus, AuthStatus.signedIn);
    expect(session.state.userId, 'user-9');
    expect(auth.updatedPasswords, isEmpty);
    await session.close();
  });
}
