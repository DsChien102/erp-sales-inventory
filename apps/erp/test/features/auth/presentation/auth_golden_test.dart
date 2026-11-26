import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/widgets/address/vn_administrative_units_loader.dart';
import 'package:erp/core/widgets/app_logo.dart';
import 'package:erp/features/auth/data/models/invitation_token_inspection.dart';
import 'package:erp/features/auth/logic/signup_cubit.dart';
import 'package:erp/features/auth/presentation/pages/invitation_token_page.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/features/auth/presentation/pages/no_organization_page.dart';
import 'package:erp/features/auth/presentation/pages/signup_page.dart';
import 'package:erp/features/auth/presentation/pages/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../iam/support/fake_iam_backend.dart';
import '../../receivable/presentation/receivable_test_harness.dart';
import '../support/scripted_auth.dart';
import '../support/scripted_invitations.dart';

/// Chụp một màn công khai ở 390 (iPhone, thanh trạng thái 30, thanh Home 34) hoặc 1280.
/// Ảnh: `docs/refactor/plans/P10/img/<folder>/flutter-<name>-<width>.png`.
Future<void> captureAuth(
  WidgetTester tester, {
  required int width,
  required String name,
  required Widget page,
  Future<void> Function()? act,
  String folder = '10-8e',
}) async {
  final phone = width == 390;
  final view = tester.view;
  view.physicalSize = phone ? const Size(390, 844) : const Size(1280, 800);
  view.devicePixelRatio = 1;
  if (phone) {
    view.padding = const FakeViewPadding(top: 30, bottom: 34);
    view.viewPadding = const FakeViewPadding(top: 30, bottom: 34);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      home: RepaintBoundary(key: key, child: page),
    ),
  );
  // Nạp logo trước để ảnh không phụ thuộc thứ tự chạy các ca.
  await tester.runAsync(
    () => precacheImage(const AssetImage(appIconAsset), key.currentContext!),
  );
  await tester.pump(const Duration(milliseconds: 50));
  if (act != null) await act();
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(
      '${repoRoot()}/docs/refactor/plans/P10/img/$folder/flutter-$name-$width.png',
    ),
  );
}

class _HangingSignIn extends ScriptedAuthRepository {
  final gate = Completer<void>();

  @override
  Future<String> signIn({required String email, required String password}) async {
    await gate.future;
    return super.signIn(email: email, password: password);
  }
}

void main() {
  setUpAll(() async {
    await loadInterFont();
    await VnAdministrativeUnitsLoader.load();
  });

  group('login', () {
    for (final width in const [390, 1280]) {
      Future<void> run(
        WidgetTester tester,
        String name, {
        ScriptedAuthRepository? auth,
        String? organizationName,
        bool joined = false,
        String? prefilledEmail,
        Future<void> Function(WidgetTester)? act,
        bool settle = true,
      }) async {
        final session = loginSession();
        addTearDown(session.close);
        await captureAuth(
          tester,
          width: width,
          name: name,
          page: LoginPage(
            auth: auth ?? ScriptedAuthRepository(),
            session: session,
            showSuccessBanner: joined,
            organizationName: organizationName,
            prefilledEmail: prefilledEmail,
          ),
          act: act == null
              ? null
              : () async {
                  await act(tester);
                  if (settle) await tester.pumpAndSettle();
                },
        );
      }

      Future<void> fill(WidgetTester tester) async {
        await tester.enterText(find.byType(TextField).at(0), 'lan@anphat.vn');
        await tester.enterText(find.byType(TextField).at(1), 'matkhau12');
      }

      Future<void> submit(WidgetTester tester) async {
        await tester.tap(find.widgetWithText(VButton, 'Đăng nhập'));
      }

      testWidgets('login__default $width', (tester) async {
        await run(tester, 'login__default');
      });
      testWidgets('login__wrong-credentials $width', (tester) async {
        await run(
          tester,
          'login__wrong-credentials',
          auth: ScriptedAuthRepository(
            signInError: const AppException(IamBlockedCodes.invalidCredentials),
          ),
          act: (t) async {
            await fill(t);
            await submit(t);
          },
        );
      });
      testWidgets('login__network $width', (tester) async {
        await run(
          tester,
          'login__network',
          auth: ScriptedAuthRepository(
            signInError: const AppException('NETWORK_ERROR'),
          ),
          act: (t) async {
            await fill(t);
            await submit(t);
          },
        );
      });
      testWidgets('login__joined $width', (tester) async {
        await run(
          tester,
          'login__joined',
          joined: true,
          organizationName: 'Thú y An Phát',
          prefilledEmail: 'minh@anphat.vn',
        );
      });
      testWidgets('login__submitting $width', (tester) async {
        final auth = _HangingSignIn();
        addTearDown(() => auth.gate.complete());
        await run(
          tester,
          'login__submitting',
          auth: auth,
          settle: false,
          act: (t) async {
            await fill(t);
            await submit(t);
            await t.pump(const Duration(milliseconds: 100));
          },
        );
      });
    }
  });

  group('signup', () {
    Future<void> enter(WidgetTester t, Map<String, String> values) async {
      for (final entry in values.entries) {
        await t.enterText(find.byKey(Key(entry.key)), entry.value);
      }
    }

    Future<void> tap(WidgetTester t, String key) async {
      await t.ensureVisible(find.byKey(Key(key)));
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key(key)));
      await t.pumpAndSettle();
    }

    Future<void> toStore(WidgetTester t) async {
      await enter(t, {
        'signup_family_name': 'Nguyễn Thị',
        'signup_given_name': 'Lan',
        'signup_email': 'lan@anphat.vn',
        'signup_password': 'Matkhau@123',
        'signup_confirm_password': 'Matkhau@123',
      });
      await tap(t, 'signup_continue');
      // Danh sách tỉnh nạp ngoài đồng hồ giả: nhường một vòng thật để FutureBuilder nhận.
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pumpAndSettle();
    }

    Future<void> createStore(WidgetTester t) async {
      await toStore(t);
      await enter(t, {
        'signup_store_name': 'Thú y An Phát',
        'signup_store_phone': '0283 456 789',
        'signup_address': '125 Kinh Dương Vương',
      });
      await tap(t, 'field_select_province');
      final search = find.byKey(const Key('input_unit_search'));
      await t.enterText(search, 'Hồ Chí Minh');
      await t.pumpAndSettle();
      await tap(t, 'item_province_79');
      await t.enterText(search, 'An Lạc');
      await t.pumpAndSettle();
      await tap(t, 'item_ward_27460');
      await tap(t, 'signup_create');
    }

    for (final width in const [390, 1280]) {
      Future<void> run(
        WidgetTester tester,
        String name,
        Future<void> Function(WidgetTester tester)? act, {
        ScriptedAuthRepository? auth,
      }) async {
        final repo = auth ?? ScriptedAuthRepository();
        final session = loginSession();
        final cubit = SignupCubit(auth: repo, session: session);
        addTearDown(session.close);
        addTearDown(cubit.close);
        await captureAuth(
          tester,
          width: width,
          name: name,
          page: SignupPage(
            auth: repo,
            session: session,
            cubit: cubit,
            clock: () => DateTime.utc(2026, 11, 25, 9),
          ),
          act: () async {
            await tester.pumpAndSettle();
            await act?.call(tester);
            // Bước xác minh giữ focus ở ô mã như prototype; form thì không.
            if (find.byKey(const Key('otp_code_field')).evaluate().isEmpty) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
            tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
            await tester.pumpAndSettle();
          },
        );
      }

      testWidgets('signup__account $width', (tester) async {
        await run(tester, 'signup__account', null);
      });
      testWidgets('signup__account-errors $width', (tester) async {
        await run(tester, 'signup__account-errors', (t) async {
          await enter(t, {
            'signup_email': 'lan@anphat',
            'signup_password': 'abc',
          });
          await tap(t, 'signup_continue');
        });
      });
      testWidgets('signup__store $width', (tester) async {
        await run(tester, 'signup__store', toStore);
      });
      testWidgets('signup__store-errors $width', (tester) async {
        await run(tester, 'signup__store-errors', (t) async {
          await toStore(t);
          await tap(t, 'signup_create');
        });
      });
      testWidgets('signup__server-error $width', (tester) async {
        await run(
          tester,
          'signup__server-error',
          createStore,
          auth: ScriptedAuthRepository(
            signUpError: const AppException('NETWORK_ERROR'),
          ),
        );
      });
      testWidgets('signup__email-exists $width', (tester) async {
        await run(
          tester,
          'signup__email-exists',
          createStore,
          auth: ScriptedAuthRepository(
            signUpError: const AppException('PLATFORM_USER_ALREADY_EXISTS'),
          ),
        );
      });
      testWidgets('signup__verify $width', (tester) async {
        await run(tester, 'signup__verify', createStore);
      });
    }
  });

  group('verify', () {
    for (final width in const [390, 1280]) {
      Future<void> run(
        WidgetTester tester,
        String name, {
        ScriptedAuthRepository? auth,
        Future<void> Function(WidgetTester)? act,
        bool settle = true,
      }) async {
        final repo = auth ?? ScriptedAuthRepository();
        final session = loginSession();
        addTearDown(session.close);
        await captureAuth(
          tester,
          width: width,
          name: name,
          page: VerifyEmailPage(
            email: 'lan@anphat.vn',
            auth: repo,
            session: session,
            clock: () => DateTime.utc(2026, 11, 25, 9),
          ),
          act: () async {
            await act?.call(tester);
            if (settle) {
              await tester.pumpAndSettle();
            } else {
              await tester.pump(const Duration(milliseconds: 500));
            }
          },
        );
      }

      testWidgets('verify__default $width', (tester) async {
        await run(tester, 'verify__default');
      });
      testWidgets('verify__countdown $width', (tester) async {
        await run(
          tester,
          'verify__countdown',
          act: (t) async {
            await t.tap(find.byKey(const Key('signup_resend')));
            await t.pumpAndSettle();
          },
        );
      });
      testWidgets('verify__error $width', (tester) async {
        await run(
          tester,
          'verify__error',
          auth: ScriptedAuthRepository()
            ..verifyError = const AppException('OTP_INVALID'),
          act: (t) async {
            await t.enterText(
              find.descendant(
                of: find.byKey(const Key('otp_code_field')),
                matching: find.byType(TextField),
              ),
              '123456',
            );
            await t.pumpAndSettle();
          },
        );
      });
      testWidgets('verify__resend-failed $width', (tester) async {
        await run(
          tester,
          'verify__resend-failed',
          auth: ScriptedAuthRepository()
            ..resendError = const AppException(AppErrorCode.network),
          settle: false,
          act: (t) async {
            await t.tap(find.byKey(const Key('signup_resend')));
            await t.pump();
          },
        );
      });
    }
  });

  group('no-org', () {
    for (final width in const [390, 1280]) {
      testWidgets('no-org__default $width', (tester) async {
        final session = loginSession();
        addTearDown(session.close);
        await captureAuth(
          tester,
          width: width,
          name: 'no-org__default',
          page: NoOrganizationPage(session: session),
          act: () => tester.pumpAndSettle(),
        );
      });
    }
  });

  group('invitation', () {
    for (final width in const [390, 1280]) {
      Future<void> runEntry(
        WidgetTester tester,
        String name, {
        FakeIamScenario scenario = FakeIamScenario.inspectExistingAccount,
        ScriptedInvitations? invitations,
        Future<void> Function(WidgetTester)? act,
        bool settle = true,
      }) async {
        final harness = InvitationPageHarness(scenario: scenario);
        addTearDown(harness.session.close);
        final page = invitations == null
            ? harness.page
            : InvitationTokenPage(
                invitations: invitations,
                auth: harness.auth,
                session: harness.session,
                keyFactory: harness.page.keyFactory,
              );
        await captureAuth(
          tester,
          width: width,
          name: name,
          folder: '10-8f',
          page: page,
          act: () async {
            await act?.call(tester);
            if (settle) {
              await tester.pumpAndSettle();
            } else {
              await tester.pump(const Duration(milliseconds: 100));
            }
          },
        );
      }

      testWidgets('invitation__entry $width', (tester) async {
        await runEntry(tester, 'invitation__entry');
      });
      testWidgets('invitation__entry-partial $width', (tester) async {
        await runEntry(
          tester,
          'invitation__entry-partial',
          act: (t) async {
            await t.enterText(
              find
                  .descendant(
                    of: find.byKey(const Key('invitation_token_input')),
                    matching: find.byType(TextField),
                  )
                  .first,
              'K7P29',
            );
          },
        );
      });
      testWidgets('invitation__entry-invalid $width', (tester) async {
        await runEntry(
          tester,
          'invitation__entry-invalid',
          scenario: FakeIamScenario.acceptExpired,
          act: (t) async {
            await t.enterText(
              find
                  .descendant(
                    of: find.byKey(const Key('invitation_token_input')),
                    matching: find.byType(TextField),
                  )
                  .first,
              'TOKENEXP',
            );
          },
        );
      });
      testWidgets('invitation__inspecting $width', (tester) async {
        final gate = Completer<void>();
        await runEntry(
          tester,
          'invitation__inspecting',
          invitations: _HangingInspectInvitations(gate),
          settle: false,
          act: (t) async {
            await t.enterText(
              find
                  .descendant(
                    of: find.byKey(const Key('invitation_token_input')),
                    matching: find.byType(TextField),
                  )
                  .first,
              'K7P29XQM',
            );
          },
        );
        gate.complete();
        await tester.pumpAndSettle();
      });

      testWidgets('invitation__register $width', (tester) async {
        await runEntry(
          tester,
          'invitation__register',
          scenario: FakeIamScenario.inspectNewAccount,
          act: (t) async {
            await t.enterText(
              find
                  .descendant(
                    of: find.byKey(const Key('invitation_token_input')),
                    matching: find.byType(TextField),
                  )
                  .first,
              'TOKENNEW',
            );
            await t.pumpAndSettle();
            await t.tap(
              find.byKey(const Key('invitation_confirm_sheet_accept')),
            );
          },
        );
      });

      testWidgets('invitation__register-errors $width', (tester) async {
        await runEntry(
          tester,
          'invitation__register-errors',
          scenario: FakeIamScenario.inspectNewAccount,
          act: (t) async {
            await t.enterText(
              find
                  .descendant(
                    of: find.byKey(const Key('invitation_token_input')),
                    matching: find.byType(TextField),
                  )
                  .first,
              'TOKENNEW',
            );
            await t.pumpAndSettle();
            await t.tap(
              find.byKey(const Key('invitation_confirm_sheet_accept')),
            );
            await t.pumpAndSettle();
            await t.enterText(
              find.byKey(const Key('invitation_register_password')),
              '123',
            );
            await t.enterText(
              find.byKey(const Key('invitation_register_confirm_password')),
              '456',
            );
            await t.pump();
            final submit = find.byKey(const Key('invitation_accept_submit'));
            await t.ensureVisible(submit);
            await t.tap(submit);
          },
        );
      });
    }
  });
}

class _HangingInspectInvitations extends ScriptedInvitations {
  _HangingInspectInvitations(this.gate)
    : super(scenario: FakeIamScenario.inspectExistingAccount);

  final Completer<void> gate;

  @override
  Future<InvitationTokenInspection> inspect(String token) async {
    await gate.future;
    return super.inspect(token);
  }
}
