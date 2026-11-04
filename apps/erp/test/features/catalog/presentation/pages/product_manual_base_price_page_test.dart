import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/presentation/models/product_list_item_model.dart';
import 'package:erp/features/catalog/presentation/models/product_readiness_status.dart';
import 'package:erp/features/catalog/presentation/pages/product_manual_base_price_page.dart';

import '../../support/catalog_test_registry.dart';
import '../../support/recording_catalog_repositories.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  testWidgets('b1_manual_base_price_save_sends_amount', (tester) async {
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
              onPressed: () => context.push('/mbp'),
              child: const Text('Open'),
            ),
          ),
        ),
        GoRoute(
          path: '/mbp',
          builder: (context, state) => const ProductManualBasePricePage(
            product: ProductListItemModel(
              id: 'p1',
              name: 'Thuốc A',
              businessStatus: ProductBusinessStatus.active,
              readinessStatus: ProductReadinessStatus.needsReview,
              baseUnit: 'Lọ',
            ),
            basePriceCard: ProductBasePriceCardDto(
              mode: BasePriceMode.manual,
              sourceLabel: 'Nhập thủ công',
              baseUnitName: 'Lọ',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductManualBasePricePage), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('input_base_price_amount')),
      '45000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_manual_base_price_save')));
    await tester.pumpAndSettle();

    expect(recordingRepo.setManualBasePriceArgs.length, 1);
    final arg = recordingRepo.setManualBasePriceArgs.single;
    expect(arg.productId, 'p1');
    expect(arg.basePrice, 45000.0);
    expect(arg.currency, 'VND');

    expect(find.byType(ProductManualBasePricePage), findsNothing);
  });

  testWidgets('g3_title_is_gia_co_so', (tester) async {
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
              onPressed: () => context.push('/mbp'),
              child: const Text('Open'),
            ),
          ),
        ),
        GoRoute(
          path: '/mbp',
          builder: (context, state) => const ProductManualBasePricePage(
            product: ProductListItemModel(
              id: 'p1',
              name: 'Thuốc A',
              businessStatus: ProductBusinessStatus.active,
              readinessStatus: ProductReadinessStatus.needsReview,
              baseUnit: 'Lọ',
            ),
            basePriceCard: ProductBasePriceCardDto(
              mode: BasePriceMode.manual,
              sourceLabel: 'Nhập thủ công',
              baseUnitName: 'Lọ',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Giá cơ sở'), findsOneWidget);
    expect(find.textContaining('Giá vốn'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('input_base_price_amount')),
      '45000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_manual_base_price_save')));
    await tester.pumpAndSettle();

    expect(find.text('Đã lưu giá cơ sở'), findsOneWidget);
  });

  testWidgets('g4_no_note_field', (tester) async {
    registerFakeCatalog(getIt);
    final router = GoRouter(
      initialLocation: '/mbp',
      routes: [
        GoRoute(
          path: '/mbp',
          builder: (context, state) => const ProductManualBasePricePage(
            product: ProductListItemModel(
              id: 'p1',
              name: 'Thuốc A',
              businessStatus: ProductBusinessStatus.active,
              readinessStatus: ProductReadinessStatus.needsReview,
              baseUnit: 'Lọ',
            ),
            basePriceCard: ProductBasePriceCardDto(
              mode: BasePriceMode.manual,
              sourceLabel: 'Nhập thủ công',
              baseUnitName: 'Lọ',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Ghi chú'), findsNothing);
  });
}
