import 'package:erp/features/iam/logic/organization_profile_cubit.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/scripted_iam_repositories.dart';

void main() {
  testWidgets('wgt_e02_u03_fr01_01: legal form does not use endsWith 999 simulation', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ScriptedOrganizationRepository();
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh hồ sơ pháp lý'), findsOneWidget);
    expect(find.text('Lưu hồ sơ'), findsOneWidget);

    // Tax code ending with 999 must not auto-open mock duplicate sheet.
    final taxFields = find.byType(TextField);
    expect(taxFields, findsWidgets);
    await tester.enterText(taxFields.at(1), '0123456999');
    await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Mã số thuế đã được ghi nhận'), findsNothing);
    expect(repository.upserts, hasLength(1));
    await cubit.close();
  });

  testWidgets('tax code field has number keyboard, formats 13-digit, and displays helper text', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ScriptedOrganizationRepository();
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    final taxFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
    );
    expect(taxFieldFinder, findsOneWidget);
    final taxField = tester.widget<TextField>(taxFieldFinder);
    expect(taxField.keyboardType, TextInputType.number);

    expect(
      find.text('10 hoặc 12 chữ số; chi nhánh nhập đủ 13 số, dấu gạch tự thêm.'),
      findsOneWidget,
    );

    await tester.enterText(taxFieldFinder, '0123456789001');
    await tester.pumpAndSettle();

    expect(find.text('0123456789-001'), findsOneWidget);
    await cubit.close();
  });

  group('PopScope discard confirmation in legal profile form', () {
    Future<void> pumpForm(WidgetTester tester, OrganizationProfileCubit cubit) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrganizationLegalProfileFormPage(cubit: cubit),
                  ),
                ),
                child: const Text('Mở form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở form'));
      await tester.pumpAndSettle();
    }

    testWidgets('unmodified form pops directly on back without dialog', (tester) async {
      final repository = ScriptedOrganizationRepository();
      final cubit = OrganizationProfileCubit(organizationRepository: repository);
      await cubit.load();

      await pumpForm(tester, cubit);
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsNothing);
      await cubit.close();
    });

    testWidgets('modified form asks confirmation on back, can keep editing or discard', (tester) async {
      final repository = ScriptedOrganizationRepository();
      final cubit = OrganizationProfileCubit(organizationRepository: repository);
      await cubit.load();

      await pumpForm(tester, cubit);

      final taxFieldFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
      );
      await tester.enterText(taxFieldFinder, '0123456789001');
      await tester.pumpAndSettle();

      // Tap back -> dialog appears
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      // Tap 'Tiếp tục sửa' -> dialog closes, page remains, value kept
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsOneWidget);
      expect(find.text('0123456789-001'), findsOneWidget);

      // Tap back again -> discard
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsNothing);
      await cubit.close();
    });

    testWidgets('modified form asks confirmation on cancel button', (tester) async {
      final repository = ScriptedOrganizationRepository();
      final cubit = OrganizationProfileCubit(organizationRepository: repository);
      await cubit.load();

      await pumpForm(tester, cubit);

      final taxFieldFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nhập mã số thuế',
      );
      await tester.enterText(taxFieldFinder, '0123456789001');
      await tester.pumpAndSettle();

      // Tap 'Hủy' button
      await tester.tap(find.widgetWithText(VButton, 'Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh hồ sơ pháp lý'), findsNothing);
      await cubit.close();
    });
  });
}
