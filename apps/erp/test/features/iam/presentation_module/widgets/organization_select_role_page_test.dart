import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/iam/presentation/users/models/user_ui_model.dart';
import 'package:erp/features/iam/presentation/users/views/organization_select_role_page.dart';

void main() {
  const sampleMember = MemberUiModel(
    id: 'mem-1',
    name: 'Nguyễn Văn Minh',
    email: 'minh@minhphat.vn',
    role: 'Nhân viên bán hàng',
    status: MemberStatus.active,
  );

  testWidgets('OrganizationSelectRolePage renders role options (TA-D-03)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationSelectRolePage(
          member: sampleMember,
          onConfirm: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chọn vai trò'), findsOneWidget);
    expect(find.text('Nguyễn Văn Minh'), findsOneWidget);
    expect(find.text('Chọn vai trò mới'), findsOneWidget);

    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Kế toán'), findsOneWidget);
    expect(find.text('Thủ kho'), findsOneWidget);
    expect(find.text('Chủ cửa hàng'), findsOneWidget);

    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets(
      'initially does not auto-select any role and enables Tiếp tục on tap',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationSelectRolePage(
          member: sampleMember,
          onConfirm: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tiếp tục is disabled initially
    final continueButtonInitial = tester.widget<VButton>(
      find.widgetWithText(VButton, 'Tiếp tục'),
    );
    expect(continueButtonInitial.onPressed, isNull);

    // Tap on Kế toán to select
    await tester.tap(find.text('Kế toán'));
    await tester.pumpAndSettle();

    // Radio is now checked (groupValue matches value)
    final radioGroup = tester.widget<RadioGroup<String>>(
      find.byType(RadioGroup<String>),
    );
    expect(radioGroup.groupValue, 'accountant');

    // Tiếp tục is now enabled
    final continueButtonSelected = tester.widget<VButton>(
      find.widgetWithText(VButton, 'Tiếp tục'),
    );
    expect(continueButtonSelected.onPressed, isNotNull);
  });

  testWidgets('Tiếp tục opens the confirm sheet with from → to', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const minMember = MemberUiModel(
      id: 'mem-1',
      name: 'Trần Văn Minh',
      email: 'minh@minhphat.vn',
      role: 'Nhân viên bán hàng',
      status: MemberStatus.active,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationSelectRolePage(
          member: minMember,
          onConfirm: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thủ kho'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.text('Đổi vai trò của Trần Văn Minh?'), findsOneWidget);
    expect(
      find.textContaining('Vai trò Nhân viên bán hàng → Thủ kho.'),
      findsOneWidget,
    );
  });

  testWidgets('Quay lại keeps the selection', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationSelectRolePage(
          member: sampleMember,
          onConfirm: (_) async {
            confirmed = true;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thủ kho'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Quay lại'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
    final radioGroup = tester.widget<RadioGroup<String>>(
      find.byType(RadioGroup<String>),
    );
    expect(radioGroup.groupValue, 'warehouse');
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
          home: OrganizationSelectRolePage(
            member: sampleMember,
            onConfirm: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
