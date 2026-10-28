import 'package:erp/features/auth/data/models/signup_input.dart';
import 'package:erp/features/auth/logic/signup_cubit.dart';
import 'package:erp/features/auth/presentation/pages/signup_page.dart';
import 'package:erp/core/widgets/address/administrative_units_form_section.dart';
import 'package:erp/core/widgets/address/vn_administrative_units_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/scripted_auth.dart';

void main() {
  testWidgets('administrative unit errors use required labels and danger borders', (
    tester,
  ) async {
    const ward = VnWard(
      code: '00001',
      fullName: 'Xã thử nghiệm',
      provinceCode: '01',
    );
    const province = VnAdministrativeUnit(
      code: '01',
      fullName: 'Tỉnh thử nghiệm',
      wards: [ward],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: AdministrativeUnitsFormSection(
            unitsFuture: Future.value(const [province]),
            isRequired: true,
            provinceError: 'Chọn tỉnh',
            communeError: 'Chọn xã',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(' *'), findsNWidgets(2));
    final provinceField = find.byKey(const Key('field_select_province'));
    final provinceContainer = find.descendant(
      of: provinceField,
      matching: find.byType(Container),
    );
    final decoration = tester.widget<Container>(provinceContainer).decoration!;
    final colors = tester.element(provinceField).vColors;
    expect((decoration as BoxDecoration).border!.top.color, colors.danger);
  });

  testWidgets('typing after account validation does not move the scroll position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 568);
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

    final continueButton = find.byKey(const Key('signup_continue'));
    await tester.ensureVisible(continueButton);
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    final familyNameField = find.byKey(const Key('signup_family_name'));
    await tester.ensureVisible(familyNameField);
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final scrollOffset = scrollable.position.pixels;

    await tester.enterText(familyNameField, 'Nguyen');
    await tester.pumpAndSettle();

    expect(
      (scrollable.position.pixels - scrollOffset).abs(),
      lessThanOrEqualTo(10),
    );
  });

  testWidgets('signup walks account, store, then email verification', (
    tester,
  ) async {
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

    expect(find.bySemanticsLabel('1/3 · Tài khoản'), findsOneWidget);
    expect(find.text('Đăng ký cửa hàng'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('signup_family_name')),
      'Nguyen',
    );
    await tester.enterText(find.byKey(const Key('signup_given_name')), 'Lan');
    await tester.enterText(
      find.byKey(const Key('signup_email')),
      'lan@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signup_password')),
      'password-1',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm_password')),
      'password-1',
    );
    await tester.tap(find.byKey(const Key('signup_continue')));
    await tester.pump();

    expect(find.bySemanticsLabel('2/3 · Cửa hàng'), findsOneWidget);
    expect(find.text('Tạo cửa hàng'), findsOneWidget);

    await tester.tap(find.byKey(const Key('signup_create')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng chọn tỉnh / thành phố'), findsOneWidget);
    expect(find.text('Vui lòng chọn xã / phường'), findsOneWidget);
    expect(find.text(' *'), findsAtLeastNWidgets(2));

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

    expect(find.bySemanticsLabel('3/3 · Xác minh email'), findsOneWidget);
    expect(find.text('Xác minh'), findsOneWidget);
    expect(auth.storeSignUps, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
