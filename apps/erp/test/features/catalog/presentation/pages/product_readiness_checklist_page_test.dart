import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/presentation/models/product_list_item_model.dart';
import 'package:erp/features/catalog/presentation/models/product_readiness_status.dart';
import 'package:erp/features/catalog/presentation/pages/product_readiness_checklist_page.dart';

import '../../support/catalog_test_registry.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  const product = ProductListItemModel(
    id: 'p1',
    name: 'Thuốc A',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
    baseUnit: 'Lọ',
  );

  Widget buildHarness({
    required List<ReadinessBlockerDto> blockers,
    List<CustomFieldGroupCardDto> customFieldGroupCards = const [],
  }) {
    registerFakeCatalog(getIt);

    final readinessView = ProductReadinessViewDto(
      productId: 'p1',
      productName: 'Thuốc A',
      readinessSummary: ReadinessSummaryDto(
        status: ReadinessStatus.incomplete,
        blockers: blockers,
      ),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/checklist'),
              child: const Text('Open'),
            ),
          ),
        ),
        GoRoute(
          path: '/checklist',
          builder: (context, state) => ProductReadinessChecklistPage(
            product: product,
            readinessView: readinessView,
            customFieldGroupCards: customFieldGroupCards,
          ),
        ),
        GoRoute(
          path: '/products/items/:productId/measurement-units',
          builder: (_, _) => const Scaffold(body: Text('route:measurement-units')),
        ),
        GoRoute(
          path: '/products/items/:productId/images-maintenance',
          builder: (_, _) => const Scaffold(body: Text('route:images-maintenance')),
        ),
        GoRoute(
          path: '/products/items/:productId/stock',
          builder: (_, _) => const Scaffold(body: Text('route:stock')),
        ),
        GoRoute(
          path: '/products/items/:productId/manual-base-price',
          builder: (_, _) => const Scaffold(body: Text('route:manual-base-price')),
        ),
        GoRoute(
          path: '/products/items/:productId/price-bands',
          builder: (_, _) => const Scaffold(body: Text('route:price-bands')),
        ),
        GoRoute(
          path: '/products/items/:productId/custom-fields/edit',
          builder: (_, _) => const Scaffold(body: Text('route:custom-fields/edit')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  final testCases = [
    ('missing_base_unit', 'route:measurement-units'),
    ('missing_image', 'route:images-maintenance'),
    ('missing_stock', 'route:stock'),
    ('missing_price', 'route:manual-base-price'),
    ('missing_price_band', 'route:price-bands'),
    ('missing_required_custom_fields', 'route:custom-fields/edit'),
  ];

  for (final (code, expectedRoute) in testCases) {
    testWidgets('b2_${code}_navigates', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          blockers: [ReadinessBlockerDto(code: code, message: 'msg-$code')],
          customFieldGroupCards: code == 'missing_required_custom_fields'
              ? const [
                  CustomFieldGroupCardDto(
                    groupId: 'g1',
                    name: 'Nhóm 1',
                    hasRequiredMissing: true,
                  ),
                ]
              : const [],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('msg-$code'));
      await tester.pumpAndSettle();

      expect(find.text(expectedRoute), findsOneWidget);
    });
  }

  testWidgets('b2_requires_base_unit_first', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        blockers: const [
          ReadinessBlockerDto(
            code: 'missing_base_unit',
            message: 'msg-missing_base_unit',
          ),
          ReadinessBlockerDto(
            code: 'missing_price',
            message: 'msg-missing_price',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('msg-missing_price'));
    await tester.pumpAndSettle();

    expect(
      find.text('Vui lòng thiết lập đơn vị cơ sở trước.'),
      findsOneWidget,
    );
    expect(find.text('route:manual-base-price'), findsNothing);
  });

  testWidgets('g7_pending_blockers_hide_cta_and_no_action', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        blockers: const [
          ReadinessBlockerDto(
            code: 'pending_stock_from_inventory',
            message: 'msg-pending-stock',
          ),
          ReadinessBlockerDto(
            code: 'pending_base_price_from_costing',
            message: 'msg-pending-costing',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('msg-pending-stock'), findsOneWidget);
    expect(find.text('msg-pending-costing'), findsOneWidget);

    // Ẩn nút CTA cho blocker chờ module khác
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('Xem Kho'), findsNothing);
    expect(find.text('Xem Giá vốn'), findsNothing);
    expect(find.text('Nhập tồn kho'), findsNothing);
    expect(find.text('Thiết lập giá cơ sở'), findsNothing);

    // Tap vào blocker không nhảy route và không toast
    await tester.tap(find.text('msg-pending-stock'));
    await tester.pumpAndSettle();
    expect(find.textContaining('route:'), findsNothing);
    expect(find.textContaining('đang được xây dựng'), findsNothing);
    expect(find.textContaining('hoàn thiện ở màn sau'), findsNothing);

    await tester.tap(find.text('msg-pending-costing'));
    await tester.pumpAndSettle();
    expect(find.textContaining('route:'), findsNothing);
    expect(find.textContaining('đang được xây dựng'), findsNothing);
    expect(find.textContaining('hoàn thiện ở màn sau'), findsNothing);
  });

  testWidgets('g7_unknown_code_no_toast', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        blockers: const [
          ReadinessBlockerDto(
            code: 'unknown_future_code',
            message: 'msg-unknown',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('msg-unknown'), findsOneWidget);

    await tester.tap(find.text('msg-unknown'));
    await tester.pumpAndSettle();

    expect(find.textContaining('đang được xây dựng'), findsNothing);
    expect(find.textContaining('hoàn thiện ở màn sau'), findsNothing);
  });
}
