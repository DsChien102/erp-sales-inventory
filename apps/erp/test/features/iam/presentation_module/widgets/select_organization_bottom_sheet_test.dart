import 'package:erp/core/session/models/accessible_tenant.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import 'package:erp/features/iam/presentation/organizations/widgets/select_organization_bottom_sheet.dart';

const _fixtureOrganizations = <AccessibleTenant>[
  AccessibleTenant(
    id: 'org-01',
    name: 'Thú y Minh Phát',
    code: 'TEN-000138',
    roleCode: 'Chủ cửa hàng',
    status: TenantStatus.active,
    isCurrent: true,
  ),
  AccessibleTenant(
    id: 'org-02',
    name: 'Phòng khám Minh Tâm',
    code: 'TEN-000204',
    roleCode: 'Kế toán',
    status: TenantStatus.active,
  ),
  AccessibleTenant(
    id: 'org-03',
    name: 'ASC Commerce',
    code: 'TEN-000095',
    roleCode: 'Nhân viên bán hàng',
    status: TenantStatus.suspended,
  ),
];

void main() {
  testWidgets(
    'SelectOrganizationBottomSheet renders list of organizations (TA-O-01)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectOrganizationBottomSheet(
              organizations: _fixtureOrganizations,
            ),
          ),
        ),
      );

      expect(find.text('Chọn tổ chức'), findsOneWidget);
      expect(find.text('Tìm theo tên hoặc mã tổ chức'), findsOneWidget);

      expect(find.text('Thú y Minh Phát'), findsOneWidget);
      expect(
        find.textContaining('TEN-000138 · Chủ cửa hàng'),
        findsOneWidget,
      );
      // Đã bỏ hậu tố 'Hiện tại'
      expect(find.textContaining('Hiện tại'), findsNothing);

      expect(find.text('Phòng khám Minh Tâm'), findsOneWidget);
      expect(find.textContaining('TEN-000204 · Kế toán'), findsOneWidget);

      expect(find.text('ASC Commerce'), findsOneWidget);
      expect(
        find.textContaining('TEN-000095 · Nhân viên bán hàng · Tạm ngừng'),
        findsOneWidget,
      );

      // Xác minh sử dụng component chuẩn VCard và VRadio
      expect(find.byType(VCard), findsNWidgets(3));
      expect(find.byType(VRadio<String>), findsNWidgets(3));
    },
  );

  testWidgets(
    'SelectOrganizationBottomSheet maps technical roleCode store_owner to Chủ cửa hàng',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectOrganizationBottomSheet(
              organizations: [
                AccessibleTenant(
                  id: 'org-raw',
                  name: 'Sỹ Chiến',
                  code: 'TEN-DA84BD',
                  roleCode: 'store_owner',
                  status: TenantStatus.active,
                  isCurrent: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Sỹ Chiến'), findsOneWidget);
      // Hiển thị 'Chủ cửa hàng' thay vì 'store_owner' và không còn 'Đang thiết lập'
      expect(find.text('TEN-DA84BD · Chủ cửa hàng'), findsOneWidget);
      expect(find.textContaining('store_owner'), findsNothing);
      expect(find.textContaining('Đang thiết lập'), findsNothing);
    },
  );

  testWidgets(
    'wgt_e05_u02_fr01_01: confirm → onConfirmSwitch success toast',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var switchCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSelectOrganizationBottomSheet(
                  context: context,
                  organizations: _fixtureOrganizations,
                  onConfirmSwitch: (org) async {
                    switchCalled = true;
                    await Future<void>.delayed(
                      const Duration(milliseconds: 20),
                    );
                    return org.id == 'org-02';
                  },
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn tổ chức'), findsOneWidget);

      await tester.tap(find.text('Phòng khám Minh Tâm'));
      await tester.pumpAndSettle();

      expect(find.text('Chuyển sang Phòng khám Minh Tâm?'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);
      expect(find.text('Chuyển tổ chức'), findsOneWidget);

      await tester.tap(find.text('Chuyển tổ chức'));
      await tester.pump();

      expect(find.text('Đang chuyển tổ chức'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(switchCalled, isTrue);
      expect(find.text('Đã chuyển sang Phòng khám Minh Tâm.'), findsOneWidget);
    },
  );

  testWidgets(
    'wgt_e05_u02_fr01_01: onConfirmSwitch false shows danger toast',
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
                onPressed: () => showSelectOrganizationBottomSheet(
                  context: context,
                  organizations: _fixtureOrganizations,
                  onConfirmSwitch: (_) async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 20),
                    );
                    return false;
                  },
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng khám Minh Tâm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển tổ chức'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Không thể chuyển sang Phòng khám Minh Tâm.'),
        findsOneWidget,
      );
    },
  );

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
    },
  );
}
