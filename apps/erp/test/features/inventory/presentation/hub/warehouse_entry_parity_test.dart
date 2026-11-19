import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_router_harness.dart';

void main() {
  setUp(() async => await setUpInventoryRouterTest());
  tearDown(tearDownInventoryRouterTest);

  group('T7-G5-0a bước 0 — lối vào Kho', () {
    testWidgets('inventory_route_opens_kho', (tester) async {
      await pumpInventoryApp(tester, location: '/inventory');
      expect(
        find.descendant(
          of: find.byType(VAppBar),
          matching: find.text('Kho'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('more_kho_opens_kho', (tester) async {
      await pumpInventoryApp(tester, location: '/more');
      await tester.tap(find.text('Kho'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(VAppBar),
          matching: find.text('Kho'),
        ),
        findsOneWidget,
      );
    });
  });
}
