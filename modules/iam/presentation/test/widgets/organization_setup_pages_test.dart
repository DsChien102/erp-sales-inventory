import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  setUp(() {
    FakeOrganizationSetupData.reset();
  });

  group('OrganizationSetupPage (TA-D-03 & TA-D-04 Unified)', () {
    testWidgets('renders incomplete state (TA-D-03) when isReadyToActivate is false', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OrganizationSetupPage(
            onCompleteTap: () {
              tapCalled = true;
            },
          ),
        ),
      );

      expect(find.text('Hoàn tất thiết lập'), findsWidgets);
      expect(find.text('Điều kiện bắt buộc'), findsOneWidget);
      expect(find.text('Hồ sơ tổ chức'), findsOneWidget);
      expect(find.text('Thiếu thông tin'), findsOneWidget);
      expect(find.text('Chủ sở hữu'), findsOneWidget);
      expect(find.text('Lê Thị Lan'), findsOneWidget);
      expect(find.text('Vai trò vận hành'), findsOneWidget);
      expect(find.text('Chủ cửa hàng'), findsOneWidget);
      expect(find.text('Hồ sơ pháp lý'), findsOneWidget);
      expect(find.text('Chưa khai báo mã số thuế'), findsOneWidget);

      expect(find.text('Bổ sung thông tin tổ chức'), findsOneWidget);
      await tester.tap(find.text('Bổ sung thông tin tổ chức'));
      await tester.pumpAndSettle();

      expect(tapCalled, isTrue);
    });

    testWidgets('renders ready state (TA-D-04) when isReadyToActivate is true and triggers activation sheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FakeOrganizationSetupData.isReadyToActivate = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: OrganizationSetupPage(),
        ),
      );

      expect(find.text('Hoàn tất thiết lập'), findsWidgets);
      expect(find.text('Sẵn sàng kích hoạt'), findsOneWidget);
      expect(find.text('Các điều kiện bắt buộc đã hoàn tất. Tổ chức có thể bắt đầu vận hành.'), findsOneWidget);
      expect(find.text('Sẵn sàng'), findsOneWidget);
      expect(find.text('Thông tin cơ bản hợp lệ'), findsOneWidget);
      expect(find.text('Kích hoạt tổ chức'), findsOneWidget);

      // Tap 'Kích hoạt tổ chức' to open bottom sheet TA-O-01
      await tester.tap(find.text('Kích hoạt tổ chức'));
      await tester.pumpAndSettle();

      expect(find.text('Kích hoạt tổ chức?'), findsOneWidget);
      expect(find.text('Sau khi kích hoạt, thành viên có thể sử dụng các nghiệp vụ theo vai trò và quyền hiện hành.'), findsOneWidget);
      expect(find.text('Lý do'), findsOneWidget);
      expect(find.text('Để sau'), findsOneWidget);
      expect(find.text('Kích hoạt tổ chức'), findsOneWidget);
      expect(find.text('Kích hoạt'), findsOneWidget);
    });
  });

  group('TA-O-01 — ConfirmActivateOrganizationBottomSheet', () {
    testWidgets('pops with true on activation button tap', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showConfirmActivateOrganizationBottomSheet(
                      context: context,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Kích hoạt tổ chức?'), findsOneWidget);
      expect(find.byType(VTextField), findsOneWidget);

      await tester.enterText(find.byType(VTextField), 'Tổ chức đã sẵn sàng vận hành');
      await tester.tap(find.text('Kích hoạt'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
