import 'package:erp/features/catalog/presentation/widgets/product_change_history_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';

void main() {
  Widget buildSubject(ProductChangeHistoryEntryDto entry) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProductChangeHistoryItem(entry: entry),
        ),
      ),
    );
  }

  testWidgets('shows price-band update before and after without ratios', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        ProductChangeHistoryEntryDto(
          id: 'history-update',
          occurredAt: DateTime.utc(2026, 7, 15, 10),
          actorDisplayName: 'Nguyễn Văn A',
          changeType: ProductChangeHistoryAction.priceBandUpdated,
          summary: 'Cập nhật khung giá — Lọ',
          changeCategory: ProductChangeCategory.pricing,
          priceBandChange: const ProductPriceBandHistoryChangeDto(
            productUnitId: 'unit-lo',
            unitName: 'Lọ',
            currency: 'VND',
            trigger: ProductPriceBandHistoryTrigger.direct,
            before: ProductPriceBandHistorySnapshotDto(
              sourceType: PriceBandSourceType.ruleBased,
              listPrice: 52500,
              floorPrice: 52000,
            ),
            after: ProductPriceBandHistorySnapshotDto(
              sourceType: PriceBandSourceType.manual,
              listPrice: 55000,
              floorPrice: 53000,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cập nhật khung giá — Lọ'), findsOneWidget);
    expect(
      find.text('Theo khung giá cửa hàng → Nhập thủ công'),
      findsOneWidget,
    );
    expect(find.text('52.500 đ → 55.000 đ'), findsOneWidget);
    expect(find.text('52.000 đ → 53.000 đ'), findsOneWidget);
    expect(find.text('Nguyên nhân: Thao tác trực tiếp'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('shows price-band creation with an empty before snapshot', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        ProductChangeHistoryEntryDto(
          id: 'history-create',
          occurredAt: DateTime.utc(2026, 7, 15, 9),
          actorDisplayName: 'Nguyễn Văn A',
          changeType: ProductChangeHistoryAction.priceBandUpdated,
          summary: 'Tạo khung giá — Lọ',
          changeCategory: ProductChangeCategory.pricing,
          priceBandChange: const ProductPriceBandHistoryChangeDto(
            productUnitId: 'unit-lo',
            unitName: 'Lọ',
            currency: 'VND',
            trigger: ProductPriceBandHistoryTrigger.direct,
            after: ProductPriceBandHistorySnapshotDto(
              sourceType: PriceBandSourceType.manual,
              listPrice: 55000,
              floorPrice: 53000,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tạo khung giá — Lọ'), findsOneWidget);
    expect(find.text('Chưa có khung giá → Nhập thủ công'), findsOneWidget);
    expect(find.text('— → 55.000 đ'), findsOneWidget);
    expect(find.text('— → 53.000 đ'), findsOneWidget);
  });

  testWidgets('shows missing floor prices as dashes', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        ProductChangeHistoryEntryDto(
          id: 'history-null-floor',
          occurredAt: DateTime.utc(2026, 7, 15, 8),
          actorDisplayName: 'Hệ thống',
          changeType: ProductChangeHistoryAction.priceBandUpdated,
          summary: 'Cập nhật khung giá — Hộp',
          changeCategory: ProductChangeCategory.pricing,
          source: 'system',
          priceBandChange: const ProductPriceBandHistoryChangeDto(
            productUnitId: 'unit-hop',
            unitName: 'Hộp',
            currency: 'VND',
            trigger: ProductPriceBandHistoryTrigger.basePriceChanged,
            before: ProductPriceBandHistorySnapshotDto(
              sourceType: PriceBandSourceType.customConfig,
              listPrice: 100000,
            ),
            after: ProductPriceBandHistorySnapshotDto(
              sourceType: PriceBandSourceType.customConfig,
              listPrice: 110000,
            ),
          ),
        ),
      ),
    );

    expect(find.text('— → —'), findsOneWidget);
    expect(
      find.text('Nguyên nhân: Tự động do Giá cơ sở thay đổi'),
      findsOneWidget,
    );
  });

  testWidgets('masked pricing history does not reveal structured values', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        ProductChangeHistoryEntryDto(
          id: 'history-masked',
          occurredAt: DateTime.utc(2026, 7, 15, 7),
          actorDisplayName: 'Nguyễn Văn A',
          changeType: ProductChangeHistoryAction.priceBandUpdated,
          summary: 'Thay đổi giá (ẩn)',
          changeCategory: ProductChangeCategory.pricing,
          isSensitiveMasked: true,
          priceBandChange: const ProductPriceBandHistoryChangeDto(
            productUnitId: 'unit-lo',
            unitName: 'Lọ',
            currency: 'VND',
            trigger: ProductPriceBandHistoryTrigger.direct,
            after: ProductPriceBandHistorySnapshotDto(
              sourceType: PriceBandSourceType.manual,
              listPrice: 55000,
              floorPrice: 53000,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('55.000'), findsNothing);
    expect(find.textContaining('Nhập thủ công'), findsNothing);
    expect(find.textContaining('Thao tác trực tiếp'), findsNothing);
  });
}
