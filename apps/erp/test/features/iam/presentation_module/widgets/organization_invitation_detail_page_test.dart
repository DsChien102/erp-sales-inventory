import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

void main() {
  Future<void> pumpDetail(
    WidgetTester tester, {
    required FakeIamScenario scenario,
    String invitationId = 'inv-1',
    OrganizationInvitationDetailCubit? cubit,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
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
}
