import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingChangeHistoryGateway implements IProductChangeHistoryGateway {
  ProductChangeHistoryPage page = const ProductChangeHistoryPage(
    items: [],
    totalCount: 0,
  );
  String? lastTenantId;
  String? lastProductId;
  int? lastLimit;
  int? lastOffset;
  List<ProductChangeCategory>? lastCategories;

  @override
  Future<ProductChangeHistoryPage> listHistory({
    required String tenantId,
    required String productId,
    required int limit,
    required int offset,
    List<ProductChangeCategory> changeCategories = const [],
  }) async {
    lastTenantId = tenantId;
    lastProductId = productId;
    lastLimit = limit;
    lastOffset = offset;
    lastCategories = changeCategories;
    return page;
  }
}

ProductChangeHistoryReadRow _row({
  required String id,
  required DateTime occurredAt,
  ProductChangeCategory category = ProductChangeCategory.profile,
  bool masked = false,
}) {
  return ProductChangeHistoryReadRow(
    id: id,
    occurredAt: occurredAt,
    actorDisplayName: 'Nguyễn Văn A',
    changeType: 'update_product_profile',
    summary: masked ? 'Thay đổi giá (ẩn)' : 'Cập nhật hồ sơ',
    changeCategory: category,
    source: 'user',
    isSensitiveMasked: masked,
    valueBefore: masked ? null : 'before',
    valueAfter: masked ? null : 'after',
  );
}

void main() {
  group('EPIC-07 / US-04 change history handlers', () {
    test('scn_e07_u04_fr02_01 returns paginated history newest first', () async {
      final gateway = _RecordingChangeHistoryGateway()
        ..page = ProductChangeHistoryPage(
          items: [
            _row(
              id: 'h-2',
              occurredAt: DateTime.utc(2026, 6, 2),
              category: ProductChangeCategory.pricing,
            ),
            _row(
              id: 'h-1',
              occurredAt: DateTime.utc(2026, 6, 1),
            ),
          ],
          totalCount: 2,
        );
      final handler = GetProductChangeHistoryQueryHandler(
        changeHistoryGateway: gateway,
      );

      final result = await handler.handle(
        GetProductChangeHistoryQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          limit: 10,
          offset: 0,
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.totalCount, 2);
      expect(result.items.first.id, 'h-2');
      expect(gateway.lastProductId, 'product-1');
      expect(gateway.lastLimit, 10);
    });

    test('scn_e07_u04_fr02_02 returns empty history', () async {
      final gateway = _RecordingChangeHistoryGateway();
      final handler = GetProductChangeHistoryQueryHandler(
        changeHistoryGateway: gateway,
      );

      final result = await handler.handle(
        GetProductChangeHistoryQuery(
          tenantId: 'tenant-1',
          productId: 'product-6',
        ),
      );

      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
    });

    test('scn_e07_u04_fr02_03 forwards category filter to gateway', () async {
      final gateway = _RecordingChangeHistoryGateway()
        ..page = ProductChangeHistoryPage(
          items: [
            _row(
              id: 'h-pricing',
              occurredAt: DateTime.utc(2026, 6, 2),
              category: ProductChangeCategory.pricing,
            ),
          ],
          totalCount: 1,
        );
      final handler = GetProductChangeHistoryQueryHandler(
        changeHistoryGateway: gateway,
      );

      final result = await handler.handle(
        GetProductChangeHistoryQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          changeCategories: const [ProductChangeCategory.pricing],
        ),
      );

      expect(gateway.lastCategories, [ProductChangeCategory.pricing]);
      expect(
        result.items.every(
          (entry) => entry.changeCategory == ProductChangeCategory.pricing,
        ),
        isTrue,
      );
    });

    test('scn_e07_u04_fr03_01 propagates permission errors', () async {
      final gateway = _RecordingChangeHistoryGateway();
      final handler = GetProductChangeHistoryQueryHandler(
        changeHistoryGateway: _ThrowingChangeHistoryGateway(),
      );

      await expectLater(
        handler.handle(
          GetProductChangeHistoryQuery(
            tenantId: 'tenant-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ApplicationException>()),
      );

      expect(gateway.lastProductId, isNull);
    });

    test('scn_e07_u04_fr03_02 propagates masked pricing rows', () async {
      final gateway = _RecordingChangeHistoryGateway()
        ..page = ProductChangeHistoryPage(
          items: [
            _row(
              id: 'h-pricing',
              occurredAt: DateTime.utc(2026, 6, 2),
              category: ProductChangeCategory.pricing,
              masked: true,
            ),
          ],
          totalCount: 1,
        );
      final handler = GetProductChangeHistoryQueryHandler(
        changeHistoryGateway: gateway,
      );

      final result = await handler.handle(
        GetProductChangeHistoryQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          changeCategories: const [ProductChangeCategory.pricing],
        ),
      );

      final entry = result.items.single;
      expect(entry.isSensitiveMasked, isTrue);
      expect(entry.valueBefore, isNull);
      expect(entry.valueAfter, isNull);
    });

    test('scn_e07_u04_validation rejects invalid query', () async {
      final validator = GetProductChangeHistoryQueryValidator();

      await expectLater(
        validator.validate(
          GetProductChangeHistoryQuery(
            tenantId: 'tenant-1',
            productId: '',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      await expectLater(
        validator.validate(
          GetProductChangeHistoryQuery(
            tenantId: 'tenant-1',
            productId: 'product-1',
            limit: 0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      await expectLater(
        validator.validate(
          GetProductChangeHistoryQuery(
            tenantId: 'tenant-1',
            productId: 'product-1',
            offset: -1,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

final class _ThrowingChangeHistoryGateway implements IProductChangeHistoryGateway {
  @override
  Future<ProductChangeHistoryPage> listHistory({
    required String tenantId,
    required String productId,
    required int limit,
    required int offset,
    List<ProductChangeCategory> changeCategories = const [],
  }) {
    throw ApplicationException('Permission denied');
  }
}
