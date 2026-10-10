import 'package:erp/features/auth/data/models/signup_input.dart';
import 'package:erp/features/auth/logic/signup_cubit.dart';
import 'package:erp/features/auth/presentation/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/scripted_auth.dart';

void main() {
  testWidgets('signup walks account, store, then email verification', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = ScriptedAuthRepository();
    final session = loginSession();
    final cubit = SignupCubit(auth: auth, session: session);
    addTearDown(session.close);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: SignupPage(auth: auth, session: session, cubit: cubit),
      ),
    );

    expect(find.text('1/3 · Tài khoản'), findsOneWidget);
    expect(find.text('Đăng ký cửa hàng'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signup_family_name')), 'Nguyen');
    await tester.enterText(find.byKey(const Key('signup_given_name')), 'Lan');
    await tester.enterText(find.byKey(const Key('signup_email')), 'lan@example.com');
    await tester.enterText(find.byKey(const Key('signup_password')), 'password-1');
    await tester.enterText(find.byKey(const Key('signup_confirm_password')), 'password-1');
    await tester.tap(find.byKey(const Key('signup_continue')));
    await tester.pump();

    expect(find.text('2/3 · Cửa hàng'), findsOneWidget);
    expect(find.text('Tạo cửa hàng'), findsOneWidget);

    await cubit.createStore(
      const SignupStoreInput(
        name: 'Thú y An Phát',
        contactPhone: '0912345678',
        provinceCode: '01',
        communeCode: '00001',
        addressText: '12 Nguyen Trai',
      ),
    );
    await tester.pump();

    expect(find.text('3/3 · Xác minh email'), findsOneWidget);
    expect(find.text('Xác minh'), findsOneWidget);
    expect(auth.storeSignUps, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
