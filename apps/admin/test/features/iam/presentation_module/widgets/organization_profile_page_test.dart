import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('wgt_e02_u01_fr01_01: loads tenant profile without mock defaults', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationProfilePage(
          iamModule: FakeIamModule(scenario: FakeIamScenario.tenantProfileOk),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ tổ chức'), findsWidgets);
    expect(find.text('Mậu Hiên'), findsWidgets);
    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('contact@mauhien.vn'), findsOneWidget);
    expect(find.text('Thao tác'), findsOneWidget);

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Thao tác hồ sơ'), findsOneWidget);
    expect(find.text('Chỉnh sửa thông tin tổ chức'), findsOneWidget);
    expect(find.text('Chỉnh sửa hồ sơ pháp lý'), findsOneWidget);
  });

  testWidgets('forbidden shows unauthorized empty state', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationProfilePage(
          iamModule:
              FakeIamModule(scenario: FakeIamScenario.tenantProfileForbidden),
          executionContext: FakeExecutionContext(tenantId: 'org-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thao tác'), findsNothing);
  });
}
