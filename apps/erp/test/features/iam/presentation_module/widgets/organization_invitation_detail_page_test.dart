import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

void main() {
  Future<void> pumpDetail(
    WidgetTester tester, {
    required FakeIamScenario scenario,
    String invitationId = 'inv-1',
    OrganizationInvitationDetailCubit? cubit,
    Size size = const Size(800, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: scenario);
    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInvitationDetailPage(
          invitationId: invitationId,
          invitations: FakeInvitationRepository(module),
          keyFactory: FakeIdempotencyKeyFactory(),
          clock: () => DateTime.utc(2026, 7, 31),
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wgt_e03_u04_fr01_01: loads invitation by id without snapshot extra', (
    WidgetTester tester,
  ) async {
    await pumpDetail(
      tester,
      scenario: FakeIamScenario.invitationResendOk,
    );

    expect(find.text('Chi tiết lời mời'), findsOneWidget);
    expect(find.text('invitee@example.com'), findsOneWidget);
    expect(find.text('Thao tác'), findsOneWidget);
  });

  testWidgets('shows failure when invitation missing', (tester) async {
    await pumpDetail(
      tester,
      scenario: FakeIamScenario.invitationResendOk,
      invitationId: 'missing',
    );

    expect(find.text('Không tải được lời mời'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Thử lại'), findsOneWidget);
  });

  testWidgets('terminal invitation is read-only', (tester) async {
    await pumpDetail(
      tester,
      scenario: FakeIamScenario.invitationResendOk,
      invitationId: 'inv-expired',
    );

    expect(find.text('invitee@example.com'), findsNothing);
    expect(find.text('old@example.com'), findsOneWidget);
    expect(find.text('Thao tác'), findsNothing);
  });

  testWidgets('resend action sends mutation from pending detail', (
    tester,
  ) async {
    final module = FakeIamBackend(scenario: FakeIamScenario.invitationResendOk);
    final cubit = OrganizationInvitationDetailCubit(
      invitationId: 'inv-1',
      invitations: FakeInvitationRepository(module),
      keyFactory: FakeIdempotencyKeyFactory(),
    );
    await cubit.load();

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInvitationDetailPage(
          invitationId: 'inv-1',
          cubit: cubit,
          clock: () => DateTime.utc(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi lại lời mời'));
    await tester.pumpAndSettle();

    expect(module.commandsOf<ResendInvitationCommand>(), hasLength(1));
    expect(cubit.state.invitation?.version, 2);
    await cubit.close();
  });

  testWidgets(
    'revoke shows one toast and returns to the list',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.invitationRevokeOk);
      final invitationsRepo = FakeInvitationRepository(module);

      final router = GoRouter(
        initialLocation: '/more/users',
        routes: [
          GoRoute(
            path: '/more/users',
            builder: (context, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/more/users/invitations/inv-1'),
                  child: const Text('Mở chi tiết'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/more/users/invitations/:id',
            builder: (_, state) => OrganizationInvitationDetailPage(
              invitationId: state.pathParameters['id']!,
              invitations: invitationsRepo,
              keyFactory: FakeIdempotencyKeyFactory(),
              clock: () => DateTime.utc(2026, 7, 31),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mở chi tiết'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thu hồi lời mời'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Sai email');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Thu hồi lời mời'));
      await tester.pumpAndSettle();

      expect(find.text('Mở chi tiết'), findsOneWidget);
      expect(find.text('Đã thu hồi lời mời.'), findsOneWidget);
    },
  );

  testWidgets('1280: resend and revoke inside the section, no Thao tác', (tester) async {
    await pumpDetail(
      tester,
      scenario: FakeIamScenario.invitationResendOk,
      size: const Size(1280, 800),
    );

    expect(find.text('Thao tác'), findsNothing);
    expect(find.widgetWithText(VButton, 'Gửi lại lời mời'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Thu hồi lời mời'), findsOneWidget);
  });

  testWidgets('1280: expired invitation has no actions', (tester) async {
    await pumpDetail(
      tester,
      scenario: FakeIamScenario.invitationResendOk,
      invitationId: 'inv-expired',
      size: const Size(1280, 800),
    );

    expect(find.widgetWithText(VButton, 'Gửi lại lời mời'), findsNothing);
    expect(find.widgetWithText(VButton, 'Thu hồi lời mời'), findsNothing);
  });

  testWidgets('revoke reason is required and spaced', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDetail(
      tester,
      scenario: FakeIamScenario.invitationRevokeOk,
    );

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thu hồi lời mời'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Lý do thu hồi'), findsOneWidget);
    expect(find.textContaining('*'), findsOneWidget);

    final descBottom = tester
        .getBottomLeft(find.text('Người nhận sẽ không thể dùng liên kết hiện tại để tham gia tổ chức.'))
        .dy;
    final labelTop = tester.getTopLeft(find.byType(VFieldLabel)).dy;
    expect(labelTop - descBottom, greaterThanOrEqualTo(16));
  });

  testWidgets('320 at text scale 2.0 does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 844),
          textScaler: TextScaler.linear(2.0),
        ),
        child: MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationInvitationDetailPage(
            invitationId: 'inv-1',
            invitations: FakeInvitationRepository(
              FakeIamBackend(scenario: FakeIamScenario.invitationResendOk),
            ),
            keyFactory: FakeIdempotencyKeyFactory(),
            clock: () => DateTime.utc(2026, 7, 31),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
