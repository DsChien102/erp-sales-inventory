import 'package:erp/features/auth/data/models/signup_input.dart';
import 'package:erp/features/auth/logic/signup_cubit.dart';
import 'package:erp/features/auth/presentation/pages/signup_page.dart';
import 'package:erp/core/widgets/address/administrative_units_form_section.dart';
import 'package:erp/core/widgets/address/vn_administrative_units_loader.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../receivable/presentation/receivable_test_harness.dart' show loadInterFont;
import '../../support/scripted_auth.dart';
import '../../support/test_router.dart';
import 'package:erp/core/errors/app_exception.dart';

void main() {
  setUpAll(loadInterFont);

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
    // Ô Xã đang tắt: mờ 0.4 như prototype; ô Tỉnh thì không.
    Finder fade(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(fade('field_select_ward')).opacity, 0.4);
    expect(fade('field_select_province'), findsNothing);
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

  group('bố cục iPhone / web (10-8e)', () {
    Future<SignupCubit> pumpAt(
      WidgetTester tester,
      Size size, {
      ScriptedAuthRepository? auth,
      double textScale = 1,
      DateTime Function()? clock,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = auth ?? ScriptedAuthRepository();
      final session = loginSession();
      final cubit = SignupCubit(auth: repo, session: session);
      addTearDown(session.close);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: SignupPage(auth: repo, session: session, cubit: cubit, clock: clock),
        ),
      );
      await tester.pumpAndSettle();
      return cubit;
    }

    const account = SignupAccountInput(
      familyName: 'Nguyen',
      givenName: 'Lan',
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
    final family = find.byKey(const Key('signup_family_name'));
    final given = find.byKey(const Key('signup_given_name'));

    testWidgets('390: names share a row 3 : 2', (tester) async {
      await pumpAt(tester, const Size(390, 844));
      expect(tester.getTopLeft(family).dy, tester.getTopLeft(given).dy);
      final ratio = tester.getSize(family).width / tester.getSize(given).width;
      expect(ratio, moreOrLessEquals(1.5, epsilon: 0.05));
    });

    testWidgets('390: error under one name keeps the row aligned at top', (
      tester,
    ) async {
      await pumpAt(tester, const Size(390, 844));
      await tester.enterText(given, 'Lan');
      await tester.tap(find.byKey(const Key('signup_continue')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập họ và tên đệm'), findsOneWidget);
      expect(tester.getTopLeft(family).dy, tester.getTopLeft(given).dy);
    });

    testWidgets('1280: card 488 wide, names stacked, login link under the card', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1280, 800));
      final card = tester.getRect(find.byType(FlowCard));
      expect(card.width, 488);
      expect(
        tester.getTopLeft(family).dy,
        lessThan(tester.getTopLeft(given).dy),
      );
      expect(tester.getTopLeft(family).dx, tester.getTopLeft(given).dx);
      expect(
        tester.getTopLeft(find.text('Đã có tài khoản? Đăng nhập')).dy,
        greaterThanOrEqualTo(card.bottom),
      );
      expect(find.text('Tài khoản'), findsWidgets);
    });

    testWidgets('1280: step 2 and 3 have no login link', (tester) async {
      final cubit = await pumpAt(tester, const Size(1280, 800));
      cubit.continueToStore(account);
      await tester.pumpAndSettle();
      expect(find.text('Đã có tài khoản? Đăng nhập'), findsNothing);
      await cubit.createStore(store);
      await tester.pumpAndSettle();
      expect(find.text('Xác minh'), findsWidgets);
      expect(find.text('Đã có tài khoản? Đăng nhập'), findsNothing);
    });

    testWidgets('resizing keeps typed values and the step', (tester) async {
      final cubit = await pumpAt(tester, const Size(900, 800));
      cubit.continueToStore(account);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('signup_store_name')),
        'Thú y Mới',
      );
      for (final size in const [Size(700, 800), Size(900, 800)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.text('Thú y Mới'), findsOneWidget);
        expect(find.byKey(const Key('signup_create')), findsOneWidget);
      }
    });

    testWidgets('resizing at step 3 keeps the typed code and cooldown', (
      tester,
    ) async {
      final auth = ScriptedAuthRepository();
      var now = DateTime.utc(2026, 11, 26, 9);
      final cubit = await pumpAt(
        tester,
        const Size(900, 800),
        auth: auth,
        clock: () => now,
      );
      cubit.continueToStore(account);
      await cubit.createStore(store);
      await tester.pumpAndSettle();
      now = now.add(const Duration(seconds: 18));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Gửi lại mã sau 00:42'), findsOneWidget);
      final code = find.descendant(
        of: find.byKey(const Key('otp_code_field')),
        matching: find.byType(TextField),
      );
      await tester.enterText(code, '123');
      await tester.pump();

      for (final size in const [Size(700, 800), Size(900, 800)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(code).controller?.text, '123');
        expect(find.text('Gửi lại mã sau 00:42'), findsOneWidget);
      }
      expect(auth.resentEmails, isEmpty);
      expect(auth.otpCodes, isEmpty);
    });

    testWidgets('resizing does not commit the autofill context', (tester) async {
      final cubit = await pumpAt(tester, const Size(900, 800));
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          null,
        ),
      );
      Future<void> resize() async {
        for (final size in const [Size(700, 800), Size(900, 800)]) {
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
        }
      }

      await resize();
      cubit.continueToStore(account);
      await tester.pumpAndSettle();
      await resize();
      expect(calls, isNot(contains('TextInput.finishAutofillContext')));

      // Rời form (sang bước xác minh) thì vẫn kết thúc như trước.
      await cubit.createStore(store);
      await tester.pumpAndSettle();
      expect(calls, contains('TextInput.finishAutofillContext'));
    });

    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      testWidgets('email exists ${size.width}: forgot link is left aligned', (
        tester,
      ) async {
        final cubit = await pumpAt(
          tester,
          size,
          auth: ScriptedAuthRepository(
            signUpError: const AppException('PLATFORM_USER_ALREADY_EXISTS'),
          ),
        );
        cubit.continueToStore(account);
        await cubit.createStore(store);
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.text('Quên mật khẩu')).dx,
          moreOrLessEquals(
            tester.getTopLeft(find.text('Email đã được đăng ký')).dx,
            epsilon: 1,
          ),
        );
      });
    }

    testWidgets('320 at text scale 2.0 does not overflow', (tester) async {
      final cubit = await pumpAt(
        tester,
        const Size(320, 568),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      cubit.continueToStore(account);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('hành vi giữ nguyên khi đổi bố cục', () {
    Future<({TestRouter harness, ScriptedAuthRepository auth, SignupCubit cubit})>
    pumpSignup(
      WidgetTester tester, {
      ScriptedAuthRepository? auth,
      String initial = '/signup',
    }) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = auth ?? ScriptedAuthRepository();
      final session = loginSession();
      final cubit = SignupCubit(auth: repo, session: session);
      addTearDown(session.close);
      addTearDown(cubit.close);
      final harness = TestRouter(
        initial: initial,
        pages: {
          '/signup': SignupPage(auth: repo, session: session, cubit: cubit),
        },
      );
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      return (harness: harness, auth: repo, cubit: cubit);
    }

    Future<void> fillAccount(WidgetTester tester) async {
      for (final entry in {
        'signup_family_name': 'Nguyen',
        'signup_given_name': 'Lan',
        'signup_email': 'lan@example.com',
        'signup_password': 'password-1',
        'signup_confirm_password': 'password-1',
      }.entries) {
        await tester.enterText(find.byKey(Key(entry.key)), entry.value);
      }
      final next = find.byKey(const Key('signup_continue'));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
    }

    const store = SignupStoreInput(
      name: 'Thú y An Phát',
      contactPhone: '0912345678',
      provinceCode: '01',
      communeCode: '00001',
      addressText: '12 Nguyen Trai',
    );

    testWidgets('back from store step returns to account', (tester) async {
      await pumpSignup(tester);
      await fillAccount(tester);
      expect(find.byKey(const Key('signup_create')), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('signup_continue')), findsOneWidget);
      expect(find.byKey(const Key('signup_create')), findsNothing);
    });

    testWidgets('back from account goes to login', (tester) async {
      await pumpSignup(tester);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN_PAGE'), findsOneWidget);
    });

    testWidgets('server error banner is scrolled into view', (tester) async {
      final r = await pumpSignup(
        tester,
        auth: ScriptedAuthRepository(signUpError: const AppException('NETWORK_ERROR')),
      );
      tester.view.physicalSize = const Size(390, 500);
      await tester.pumpAndSettle();
      await fillAccount(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      await r.cubit.createStore(store);
      await tester.pumpAndSettle();

      final banner = find.byType(VBanner);
      expect(banner, findsOneWidget);
      final top = tester.getTopLeft(banner).dy;
      expect(top, greaterThanOrEqualTo(0));
      expect(top, lessThan(500));
    });

    testWidgets('contact email defaults to account email', (tester) async {
      await pumpSignup(tester);
      await fillAccount(tester);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('signup_contact_email')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller?.text, 'lan@example.com');
    });

    testWidgets('email exists: login carries the email', (tester) async {
      final r = await pumpSignup(
        tester,
        auth: ScriptedAuthRepository(
          signUpError: const AppException('PLATFORM_USER_ALREADY_EXISTS'),
        ),
      );
      await fillAccount(tester);
      await r.cubit.createStore(store);
      await tester.pumpAndSettle();

      expect(find.text('Email đã được đăng ký'), findsOneWidget);
      expect(find.text('Quên mật khẩu'), findsOneWidget);
      await tester.tap(find.widgetWithText(VButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_PAGE'), findsOneWidget);
      expect(r.harness.extras['/login'], {'prefilledEmail': 'lan@example.com'});
    });

    testWidgets('completed shows welcome toast and goes home', (tester) async {
      final r = await pumpSignup(tester);
      await fillAccount(tester);
      await r.cubit.createStore(
        const SignupStoreInput(
          name: 'Thú y Minh Phát',
          contactPhone: '0912345678',
          provinceCode: '01',
          communeCode: '00001',
          addressText: '12 Nguyen Trai',
        ),
      );
      await tester.pumpAndSettle();
      await r.cubit.completeAfterVerification('user-9');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VToast), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(VToast),
          matching: find.textContaining('Thú y Minh Phát đã sẵn sàng'),
        ),
        findsOneWidget,
      );
      expect(find.text('HOME_PAGE'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('completed under an earlier name: one toast says both', (
      tester,
    ) async {
      final r = await pumpSignup(tester);
      await fillAccount(tester);
      await r.cubit.createStore(store);
      await tester.pumpAndSettle();
      await r.cubit.completeAfterVerification('user-9');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final toast = find.byType(VToast);
      expect(toast, findsOneWidget);
      for (final text in [
        'Thú y Minh Phát đã sẵn sàng.',
        'Cửa hàng được tạo theo thông tin lần đăng ký trước.',
        'Bạn có thể sửa trong Hồ sơ tổ chức.',
      ]) {
        expect(
          find.descendant(of: toast, matching: find.textContaining(text)),
          findsOneWidget,
          reason: text,
        );
      }
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });
  });
}
