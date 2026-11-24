import 'package:erp/core/di/injection.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:erp/features/catalog/presentation/pages/product_images_maintenance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeProductRepository extends Fake implements ProductRepository {}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<ProductRepository>(_FakeProductRepository());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('t93_sp06_8_images_disables_adding_more', (tester) async {
    final eightImages = List.generate(8, (i) => 'key-$i');
    final product = ProductListItemModel(
      id: 'prod-8',
      name: 'Thuốc 8 ảnh',
      businessStatus: ProductBusinessStatus.active,
      readinessStatus: ProductReadinessStatus.ready,
      images: eightImages,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductImagesMaintenancePage(product: product),
      ),
    );
    await tester.pumpAndSettle();

    final maxBannerFinder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Đã đạt tối đa 8 ảnh.'),
    );
    expect(maxBannerFinder, findsOneWidget);
    expect(find.text('Thêm'), findsNothing);
  });

  testWidgets('t93_sp06_under_8_images_allows_adding', (tester) async {
    final threeImages = List.generate(3, (i) => 'key-$i');
    final product = ProductListItemModel(
      id: 'prod-3',
      name: 'Thuốc 3 ảnh',
      businessStatus: ProductBusinessStatus.active,
      readinessStatus: ProductReadinessStatus.ready,
      images: threeImages,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductImagesMaintenancePage(product: product),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Chạm vào ảnh để đặt làm ảnh mặc định. Tối đa 8 ảnh.'),
      findsOneWidget,
    );
    expect(find.text('Thêm'), findsOneWidget);
  });
}
