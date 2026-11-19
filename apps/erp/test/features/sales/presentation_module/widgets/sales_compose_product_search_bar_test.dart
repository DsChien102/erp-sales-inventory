import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation.dart';

const _units = [
  SalesProductUnitVm(
    productUnitId: 'unit-1',
    unitCode: 'LO',
    unitName: 'lọ',
    unitPrice: MoneyDto(amountMinor: 11000, currencyCode: 'VND'),
    isDefault: true,
  ),
];

const _product = SalesSellableProductVm(
  productId: 'product-1',
  sku: 'SKU-001',
  displayName: 'Thuoc A',
  tradeName: 'Biet duoc A',
  units: _units,
);

void main() {
  testWidgets('compose search requests at most four live suggestions', (tester) async {
    int? capturedLimit;
    await _pumpSearch(
      tester,
      searchProducts: (_, {limit = 50}) async {
        capturedLimit = limit;
        return const [_product];
      },
    );

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(capturedLimit, 4);
    expect(find.byKey(const Key('card_compose_suggest_product-1')), findsOneWidget);
    expect(find.text('Thuoc A'), findsOneWidget);
    expect(find.text('Biet duoc A · lọ'), findsOneWidget);
  });

  testWidgets('focus opens the overlay with default suggestions on an empty query', (
    tester,
  ) async {
    final keywords = <String>[];
    await _pumpSearch(
      tester,
      searchProducts: (keyword, {limit = 50}) async {
        keywords.add(keyword);
        return const [_product];
      },
    );

    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(keywords, ['']);
    expect(find.byKey(const Key('wgt_compose_product_suggestions')), findsOneWidget);
    expect(find.byKey(const Key('card_compose_suggest_product-1')), findsOneWidget);
  });

  testWidgets('search failure never renders a fake suggestion', (tester) async {
    await _pumpSearch(
      tester,
      searchProducts: (_, {limit = 50}) => throw Exception('catalog down'),
    );

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byKey(const Key('wgt_compose_product_suggestions')), findsNothing);
    expect(find.byKey(const Key('wgt_compose_product_error')), findsOneWidget);
    expect(find.textContaining('catalog down'), findsOneWidget);
  });

  testWidgets('no match renders the empty state inside the overlay', (tester) async {
    await _pumpSearch(
      tester,
      searchProducts: (_, {limit = 50}) async => const [],
    );

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byKey(const Key('wgt_compose_product_empty')), findsOneWidget);
    expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
    expect(find.byKey(const Key('wgt_compose_product_suggestions')), findsNothing);
    expect(find.byType(VToast), findsNothing);
  });

  testWidgets('search bar shows a spinner only while fetching', (tester) async {
    final pending = Completer<List<SalesSellableProductVm>>();
    await _pumpSearch(
      tester,
      searchProducts: (_, {limit = 50}) => pending.future,
    );

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(VLoading), findsOneWidget);

    pending.complete(const [_product]);
    await tester.pump();
    await tester.pump();

    expect(find.byType(VLoading), findsNothing);
    expect(find.byKey(const Key('card_compose_suggest_product-1')), findsOneWidget);
  });

  testWidgets('unfocus during inflight search discards result and keeps menu closed', (
    tester,
  ) async {
    final pending = Completer<List<SalesSellableProductVm>>();
    await _pumpSearch(
      tester,
      searchProducts: (_, {limit = 50}) => pending.future,
    );

    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VLoading), findsOneWidget);
    expect(find.byKey(const Key('wgt_compose_product_suggestions')), findsNothing);

    // Tap ra ngoài → unfocus trong lúc future còn treo.
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();

    expect(find.byType(VLoading), findsNothing);
    expect(find.byKey(const Key('wgt_compose_product_suggestions')), findsNothing);

    pending.complete(const [_product]);
    await tester.pump();
    await tester.pump();

    expect(find.byType(VLoading), findsNothing);
    expect(find.byKey(const Key('wgt_compose_product_suggestions')), findsNothing);
    expect(find.byKey(const Key('card_compose_suggest_product-1')), findsNothing);
  });

  testWidgets('retry re-runs the failed search with the same keyword', (tester) async {
    final keywords = <String>[];
    await _pumpSearch(
      tester,
      searchProducts: (keyword, {limit = 50}) async {
        keywords.add(keyword);
        throw Exception('catalog down');
      },
    );

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(keywords, ['thuoc']);

    await tester.tap(find.byKey(const Key('btn_compose_search_retry')));
    await tester.pump();
    await tester.pump();

    expect(keywords, ['thuoc', 'thuoc']);
    expect(find.byKey(const Key('wgt_compose_product_error')), findsOneWidget);

    // Nút Thử lại lấy focus khỏi ô tìm kiếm, nên phải chờ hết timer ẩn overlay.
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('falls back to unit name when trade name is absent', (tester) async {
    const productWithoutTradeName = SalesSellableProductVm(
      productId: 'product-2',
      sku: 'SKU-002',
      displayName: 'Thuoc B',
      units: _units,
    );
    await _pumpSearch(
      tester,
      searchProducts: (_, {limit = 50}) async => const [productWithoutTradeName],
    );

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      'thuoc',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Thuoc B'), findsOneWidget);
    expect(find.text('lọ'), findsWidgets);
    expect(find.text('Thuoc B · lọ'), findsNothing);
  });

  testWidgets('submit resolves barcode and selects the unique owner result', (tester) async {
    SalesSellableProductVm? selected;
    String? barcode;
    await _pumpSearch(
      tester,
      searchProducts: (_, {limit = 50}) async => const [],
      resolveBarcode: (value) async {
        barcode = value;
        return const [_product];
      },
      onSelectProduct: (value) => selected = value,
    );

    await tester.enterText(
      find.byKey(const Key('input_compose_product_search')),
      '  8930001  ',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(barcode, '8930001');
    expect(selected, _product);
  });
}

Future<void> _pumpSearch(
  WidgetTester tester, {
  required SalesProductSearchFn searchProducts,
  SalesProductBarcodeResolveFn? resolveBarcode,
  ValueChanged<SalesSellableProductVm>? onSelectProduct,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: SalesComposeProductSearchBar(
          searchProducts: searchProducts,
          resolveBarcode: resolveBarcode ?? (_) async => const [],
          onSelectProduct: onSelectProduct ?? (_) {},
          onScanTap: () {},
        ),
      ),
    ),
  );
}
