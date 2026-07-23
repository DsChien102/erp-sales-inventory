import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../lib/src/organizations/widgets/select_organization_bottom_sheet.dart';
import '../../lib/src/organizations/widgets/confirm_switch_organization_bottom_sheet.dart';

void main() {
  testWidgets('SelectOrganizationBottomSheet renders list of organizations (TA-O-01)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectOrganizationBottomSheet(),
        ),
      ),
    );

    expect(find.text('Chọn tổ chức'), findsOneWidget);
    expect(find.text('Tìm theo tên hoặc mã tổ chức'), findsOneWidget);

    expect(find.text('Thú y Minh Phát'), findsOneWidget);
    expect(find.textContaining('TEN-000138 · Chủ cửa hàng · Hiện tại'), findsOneWidget);

    expect(find.text('Phòng khám Minh Tâm'), findsOneWidget);
    expect(find.textContaining('TEN-000204 · Kế toán'), findsOneWidget);

    expect(find.text('ASC Commerce'), findsOneWidget);
    expect(find.textContaining('TEN-000095 · Nhân viên bán hàng · Tạm ngừng'), findsOneWidget);
  });

  testWidgets('Selecting an available organization opens ConfirmSwitchOrganizationBottomSheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSelectOrganizationBottomSheet(context: context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn tổ chức'), findsOneWidget);

    // Tap 'Phòng khám Minh Tâm'
    await tester.tap(find.text('Phòng khám Minh Tâm'));
    await tester.pumpAndSettle();

    // Verify confirmation sheet opens
    expect(find.text('Chuyển sang Phòng khám Minh Tâm?'), findsOneWidget);
    expect(find.text('Dữ liệu và quyền truy cập sẽ được tải lại theo tổ chức đã chọn.'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
    expect(find.text('Chuyển tổ chức'), findsOneWidget);

    // Tap 'Chuyển tổ chức'
    await tester.tap(find.text('Chuyển tổ chức'));
    await tester.pump();

    // Verify VLoading dialog appears
    expect(find.text('Đang chuyển tổ chức'), findsOneWidget);
    expect(
      find.text('Đang tải dữ liệu và quyền truy cập của Phòng khám Minh Tâm.'),
      findsOneWidget,
    );

    // Advance timer to finish loading
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Verify VToast success message appears
    expect(find.text('Đã chuyển sang Phòng khám Minh Tâm.'), findsOneWidget);
  });

  testWidgets(
      'SelectOrganizationBottomSheet renders OrganizationEmptyView when organizations list is empty',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectOrganizationBottomSheet(
            organizations: [],
          ),
        ),
      ),
    );

    expect(find.text('Chưa có tổ chức được cấp quyền'), findsOneWidget);
    expect(find.text('Kiểm tra lại'), findsOneWidget);
  });
}
