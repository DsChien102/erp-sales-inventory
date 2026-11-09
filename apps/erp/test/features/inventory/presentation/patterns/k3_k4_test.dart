import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:erp/features/inventory/presentation/patterns/k3_unknown_page.dart';
import 'package:erp/features/inventory/presentation/patterns/k4_result_page.dart';
import '../../support/inventory_test_surface.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(390, 844)}) {
    useInventoryTestSurface(size);
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('K4ResultPage', () {
    testWidgets('k4_no_back_button', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K4ResultPage(
            title: 'Nhận hàng thành công',
            description: 'Đã nhập kho 2 mặt hàng.',
          ),
        ),
      );

      final scaffold = tester.widget<VPageScaffold>(find.byType(VPageScaffold));
      expect(scaffold.showBackButton, isFalse);
    });

    testWidgets('k4_stock_change_line', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K4ResultPage(
            title: 'Nhận hàng thành công',
            description: 'Đã cập nhật tồn kho.',
            stockChanges: [
              K4StockChange(
                product: 'Nobivac DHPPi',
                before: '120 hộp',
                after: '122 hộp',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Tồn kho đã đổi'), findsOneWidget);
      expect(find.text('Nobivac DHPPi 120 hộp → 122 hộp'), findsOneWidget);
    });

    testWidgets('k4_iphone_has_bottom_navigation', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K4ResultPage(
            title: 'Thành công',
            description: 'Đã lưu.',
          ),
          size: const Size(390, 844),
        ),
      );

      expect(find.byType(ErpBottomNavigation), findsOneWidget);
    });

    testWidgets('k4_web_has_no_bottom_navigation', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K4ResultPage(
            title: 'Thành công',
            description: 'Đã lưu.',
          ),
          size: const Size(1280, 800),
        ),
      );

      expect(find.byType(ErpBottomNavigation), findsNothing);
    });

    testWidgets('k4_bottom_nav_tap_goes_to_tab', (tester) async {
      String? navigatedTo;
      final router = GoRouter(
        initialLocation: '/result',
        routes: [
          GoRoute(
            path: '/result',
            builder: (context, state) => const K4ResultPage(
              title: 'Thành công',
              description: 'Đã lưu.',
            ),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) {
              navigatedTo = '/orders';
              return const Scaffold(body: Text('Orders Page'));
            },
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

      await tester.tap(find.text('Đơn hàng'));
      await tester.pumpAndSettle();

      expect(navigatedTo, '/orders');
    });
  });

  group('K3UnknownPage', () {
    testWidgets('k3_rows_and_copy', (tester) async {
      await tester.pumpWidget(
        wrap(
          K3UnknownPage(
            operation: 'Nhận hàng',
            scope: 'Kho Chính',
            ref: 'PN-260905-01',
            sentAt: '09:41',
            safe: 'Phiếu chưa được lưu.',
            onExit: () {},
          ),
        ),
      );

      expect(find.text('Kết quả chưa xác định'), findsOneWidget);
      expect(
        find.textContaining('Không gửi lại thao tác.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Phiếu chưa được lưu.'),
        findsOneWidget,
      );

      expect(find.text('Nghiệp vụ'), findsOneWidget);
      expect(find.text('Nhận hàng'), findsOneWidget);
      expect(find.text('Phạm vi'), findsOneWidget);
      expect(find.text('Kho Chính'), findsOneWidget);
      expect(find.text('Mã tham chiếu'), findsOneWidget);
      expect(find.text('PN-260905-01'), findsOneWidget);
      expect(find.text('Thời điểm gửi'), findsOneWidget);
      expect(find.text('09:41'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Chưa kết luận'), findsOneWidget);

      expect(find.byType(ErpBottomNavigation), findsNothing);
    });

    testWidgets('k3_two_buttons_when_verify', (tester) async {
      await tester.pumpWidget(
        wrap(
          K3UnknownPage(
            operation: 'Nhận hàng',
            scope: 'Kho Chính',
            ref: 'PN-01',
            sentAt: '09:41',
            onExit: () {},
            onVerify: () {},
          ),
        ),
      );

      expect(find.text('Về Kho'), findsOneWidget);
      expect(find.text('Chuyển sang xác minh'), findsOneWidget);
    });

    testWidgets('k3_only_exit_when_verify_null', (tester) async {
      await tester.pumpWidget(
        wrap(
          K3UnknownPage(
            operation: 'Nhận hàng',
            scope: 'Kho Chính',
            ref: 'PN-01',
            sentAt: '09:41',
            onExit: () {},
            onVerify: null,
          ),
        ),
      );

      expect(find.text('Về Kho'), findsOneWidget);
      expect(find.text('Chuyển sang xác minh'), findsNothing);
    });
  });
}
