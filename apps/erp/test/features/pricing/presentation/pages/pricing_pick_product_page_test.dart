// H20: PricingPickProductPage tìm sản phẩm qua catalog ProductRepository.
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_pick_product_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

final class _MockProductRepository extends Fake implements ProductRepository {
  _MockProductRepository({this.onSearch});

  final Future<ProductSearchResultDto> Function({
    ProductSearchCriteria? criteria,
    int limit,
    int offset,
  })? onSearch;

  ProductSearchCriteria? lastCriteria;
  int? lastLimit;

  @override
  Future<ProductSearchResultDto> search({
    ProductSearchCriteria? criteria,
    int limit = 50,
    int offset = 0,
  }) async {
    lastCriteria = criteria;
    lastLimit = limit;
    if (onSearch != null) {
      return onSearch!(criteria: criteria, limit: limit, offset: offset);
    }
    return const ProductSearchResultDto(
      items: [],
      totalCount: 0,
    );
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<_MockProductRepository> pump(
    WidgetTester tester, {
    Future<ProductSearchResultDto> Function({
      ProductSearchCriteria? criteria,
      int limit,
      int offset,
    })? onSearch,
  }) async {
    final repo = _MockProductRepository(onSearch: onSearch);
    getIt.registerSingleton<ProductRepository>(repo);
    await tester.pumpWidget(const MaterialApp(home: PricingPickProductPage()));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('tìm sản phẩm: limit 30 và hiển thị tên sản phẩm (H20)', (tester) async {
    final repo = await pump(
      tester,
      onSearch: ({criteria, limit = 50, offset = 0}) async {
        return ProductSearchResultDto(
          items: [
            ProductListItemDto(
              id: 'prod-1',
              name: 'Sản phẩm thử nghiệm A',
              businessStatus: ProductBusinessStatus.active,
              readinessSummary: const ReadinessSummaryDto(
                status: ReadinessStatus.readyToSell,
              ),
              updatedAt: DateTime(2026, 1, 1),
            ),
          ],
          totalCount: 1,
        );
      },
    );

    expect(repo.lastLimit, 30);
    expect(find.text('Sản phẩm thử nghiệm A'), findsOneWidget);
  });

  testWidgets('lỗi tải sản phẩm → hiển thị "Không tải được danh sách sản phẩm." (H20)', (tester) async {
    await pump(
      tester,
      onSearch: ({criteria, limit = 50, offset = 0}) async {
        throw const AppException('NO_PERMISSION');
      },
    );

    expect(find.text('Không tải được danh sách sản phẩm.'), findsOneWidget);
  });
}
