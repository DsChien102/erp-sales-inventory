import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/models/store_price_rule.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/presentation/pages/settings/edit_store_price_rule_page.dart';

import '../../../support/catalog_test_registry.dart';
import '../../../support/recording_catalog_repositories.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  testWidgets('b1_store_rule_save_sends_ratios', (tester) async {
    final backend = registerFakeCatalog(getIt);
    final recordingRepo = RecordingPriceRepository(backend: backend);
    getIt.unregister<ProductPriceRepository>();
    getIt.registerSingleton<ProductPriceRepository>(recordingRepo);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/edit'),
              child: const Text('Open'),
            ),
          ),
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) => const EditStorePriceRulePage(
            existingRule: StorePriceRuleDto(
              id: 'r1',
              tenantId: 't1',
              name: 'Khung giá cửa hàng',
              status: StorePriceRuleStatus.active,
              calculationType: StorePriceCalculationType.markup,
              listMarkupRatio: 0.3,
              floorMarkupRatio: 0.1,
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(EditStorePriceRulePage), findsOneWidget);

    // First TextField is list markup
    final listMarkupFinder = find.byType(TextField).first;
    await tester.enterText(listMarkupFinder, '35');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(find.text('Áp dụng'), findsOneWidget);
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(recordingRepo.setStorePriceRuleArgs.length, 1);
    final arg = recordingRepo.setStorePriceRuleArgs.single;
    expect(arg.listMarkupRatio, 0.35);
    expect(arg.floorMarkupRatio, 0.1);
    expect(arg.status, StorePriceRuleStatus.active);
    expect(arg.name, 'Khung giá cửa hàng');

    expect(find.text('Đã cập nhật khung giá cửa hàng.'), findsOneWidget);
    expect(find.byType(EditStorePriceRulePage), findsNothing);
  });

  testWidgets('g4_no_note_field', (tester) async {
    registerFakeCatalog(getIt);
    final router = GoRouter(
      initialLocation: '/edit',
      routes: [
        GoRoute(
          path: '/edit',
          builder: (context, state) => const EditStorePriceRulePage(
            existingRule: StorePriceRuleDto(
              id: 'r1',
              tenantId: 't1',
              name: 'Khung giá cửa hàng',
              status: StorePriceRuleStatus.active,
              calculationType: StorePriceCalculationType.markup,
              listMarkupRatio: 0.3,
              floorMarkupRatio: 0.1,
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Ghi chú (tuỳ chọn)'), findsNothing);
  });
}
