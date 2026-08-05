import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('wgt_e02_u02_fr01_01: edit profile submits UpdateTenantProfileCommand', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileUpdateOk),
    );
    final cubit = OrganizationProfileCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationEditProfilePage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh thông tin tổ chức'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Mậu Hiên Updated');
    await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(module.commandsOf<UpdateTenantProfileCommand>(), hasLength(1));
    expect(
      module.commandsOf<UpdateTenantProfileCommand>().single.displayName,
      'Mậu Hiên Updated',
    );
    await cubit.close();
  });

  testWidgets('marks readiness blocker contact fields as required', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationProfileCubit(
      iamModule: FakeIamModule(scenario: FakeIamScenario.tenantProfileOk),
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationEditProfilePage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(_richTextContaining('Tên tổ chức *'), findsOneWidget);
    expect(_richTextContaining('Số điện thoại *'), findsOneWidget);
    expect(_richTextContaining('Email liên hệ *'), findsOneWidget);
    expect(_richTextContaining('Địa chỉ liên hệ *'), findsOneWidget);
    expect(_richTextContaining('Tỉnh / thành phố *'), findsNothing);
    expect(_richTextContaining('Xã / phường *'), findsNothing);

    await cubit.close();
  });
}

Finder _richTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(text),
  );
}
