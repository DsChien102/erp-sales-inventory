import 'package:erp/core/errors/app_exception.dart';
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
    final cubit = SignupCubit(auth: ScriptedAuthRepository());

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
  });

  test('back keeps the account already entered', () async {
    final cubit = SignupCubit(auth: ScriptedAuthRepository());

    cubit.continueToStore(account);
    cubit.back();

    expect(cubit.state.step, SignupStep.account);
    expect(cubit.state.account?.email, 'lan@example.com');
    await cubit.close();
  });

  test('missing address does not call signUpStore', () async {
    final auth = ScriptedAuthRepository();
    final cubit = SignupCubit(auth: auth);
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
  });

  test('an existing email sets emailExists', () async {
    final cubit = SignupCubit(
      auth: ScriptedAuthRepository(
        signUpError: const AppException('PLATFORM_USER_ALREADY_EXISTS'),
      ),
    );
    cubit.continueToStore(account);

    await cubit.createStore(store);

    expect(cubit.state.emailExists, isTrue);
    expect(cubit.state.failure, 'Email đã được đăng ký');
    expect(cubit.state.step, SignupStep.store);
    await cubit.close();
  });
}
