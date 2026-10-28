import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/scripted_iam_repositories.dart';

void main() {
  testWidgets('wgt_e02_u01_fr01_01: loads tenant profile without mock defaults', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationProfilePage(
          organizationRepository: ScriptedOrganizationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ tổ chức'), findsWidgets);
    expect(find.text('Mậu Hiên'), findsWidgets);
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
          organizationRepository: ScriptedOrganizationRepository(
            mode: OrganizationScript.forbidden,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thao tác'), findsNothing);
  });

  testWidgets('section headings expose header semantics', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationProfilePage(
          organizationRepository: ScriptedOrganizationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.text('Thông tin tổ chức'));
    expect(node.flagsCollection.isHeader, isTrue);

    handle.dispose();
  });
}
