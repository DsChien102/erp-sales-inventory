import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

class _FakeCatalogReadGateway implements ICatalogReadGateway {
  String? lastTenantId;
  ProductSearchCriteria? lastCriteria;
  int? lastLimit;
  int? lastOffset;
  String? lastBarcode;
  String? lastProductId;

  ProductSearchResultDto searchResult = const ProductSearchResultDto(
    items: [],
    totalCount: 0,
  );

  ProductListItemDto? barcodeResult;
  ProductControlCenterReadModel? controlCenterResult;

  @override
  Future<ProductSearchResultDto> search({
    required String tenantId,
    required ProductSearchCriteria criteria,
    required int limit,
    required int offset,
  }) async {
    lastTenantId = tenantId;
    lastCriteria = criteria;
    lastLimit = limit;
    lastOffset = offset;
    return searchResult;
  }

  @override
  Future<ProductListItemDto?> findByBarcode({
    required String tenantId,
    required String barcode,
  }) async {
    lastTenantId = tenantId;
    lastBarcode = barcode;
    return barcodeResult;
  }

  @override
  Future<ProductControlCenterReadModel?> loadControlCenter({
    required String tenantId,
    required String productId,
  }) async {
    lastTenantId = tenantId;
    lastProductId = productId;
    return controlCenterResult;
  }

  @override
  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    required String tenantId,
    required int maxOptionsPerField,
  }) async {
    return const [];
  }
}

ProductListItemDto _sampleListItem({
  ReadinessStatus status = ReadinessStatus.incomplete,
  List<ReadinessBlockerDto> blockers = const [],
}) {
  return ProductListItemDto(
    id: 'product-1',
    name: 'Amoxicillin 500mg',
    tradeName: 'Amox 500',
    sku: 'SP0001',
    barcode: '8930000000001',
    businessStatus: ProductBusinessStatus.active,
    readinessSummary: ReadinessSummaryDto(
      status: status,
      blockers: blockers,
    ),
    updatedAt: DateTime.utc(2026, 6, 1),
  );
}

ProductControlCenterReadModel _sampleControlCenterModel({
  bool hasPriceBand = false,
  bool hasBasePrice = true,
  bool hasPendingCustomConfig = false,
}) {
  return ProductControlCenterReadModel(
    productId: 'product-1',
    name: 'Amoxicillin 500mg',
    tradeName: 'Amox 500',
    sku: 'SP0001',
    barcode: '8930000000001',
    businessStatus: ProductBusinessStatus.active,
    images: const ['https://example.com/image.jpg'],
    baseUnitName: 'Hộp',
    facts: ProductReadinessFacts(
      productId: 'product-1',
      productName: 'Amoxicillin 500mg',
      hasBaseUnit: true,
      hasImages: true,
      hasStock: true,
      hasBasePrice: hasBasePrice,
      hasPriceBand: hasPriceBand,
      hasRequiredCustomFields: true,
    ),
    stockQuantity: 150,
    basePriceAmount: hasBasePrice ? 80000 : null,
    listBeforeVat: hasPriceBand ? 120000 : null,
    floorBeforeVat: hasPriceBand ? 95000 : null,
    priceBandSourceType: hasPendingCustomConfig ? PriceBandSourceType.customConfig : null,
    changeHistoryPreview: [
      ProductChangeHistoryEntryDto(
        id: 'history-1',
        occurredAt: DateTime.utc(2026, 6, 1),
        actorDisplayName: 'user-1',
        changeType: ProductChangeHistoryAction.created,
        summary: 'Tạo sản phẩm',
      ),
    ],
  );
}

void main() {
  group('SearchProductsQueryHandler', () {
    test('scn_e01_u01_fr01_01 delegates search to read gateway', () async {
      final gateway = _FakeCatalogReadGateway()
        ..searchResult = ProductSearchResultDto(
          items: [_sampleListItem()],
          totalCount: 1,
        );
      final handler = SearchProductsQueryHandler(readGateway: gateway);
      final criteria = ProductSearchCriteria(keyword: 'Amoxicillin');

      final result = await handler.handle(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: criteria,
          limit: 25,
          offset: 5,
        ),
      );

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastCriteria?.keyword, 'Amoxicillin');
      expect(gateway.lastLimit, 25);
      expect(gateway.lastOffset, 5);
      expect(result.totalCount, 1);
      expect(result.items.single.name, 'Amoxicillin 500mg');
    });

    test('rejects invalid limit', () async {
      final handler = SearchProductsQueryHandler(
        readGateway: _FakeCatalogReadGateway(),
      );

      await expectLater(
        handler.handle(
          SearchProductsQuery(
            tenantId: 'tenant-1',
            criteria: ProductSearchCriteria(),
            limit: 0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ScanBarcodeQueryHandler', () {
    test('scn_e01_u01_fr01_01 delegates barcode lookup to read gateway', () async {
      final gateway = _FakeCatalogReadGateway()
        ..barcodeResult = _sampleListItem(status: ReadinessStatus.readyToSell);
      final handler = ScanBarcodeQueryHandler(readGateway: gateway);

      final result = await handler.handle(
        ScanBarcodeQuery(
          tenantId: 'tenant-1',
          barcode: '8930000000001',
        ),
      );

      expect(gateway.lastBarcode, '8930000000001');
      expect(result?.barcode, '8930000000001');
      expect(result?.readinessSummary.status, ReadinessStatus.readyToSell);
    });

    test('returns null for blank barcode without calling gateway', () async {
      final gateway = _FakeCatalogReadGateway();
      final handler = ScanBarcodeQueryHandler(readGateway: gateway);

      final result = await handler.handle(
        ScanBarcodeQuery(tenantId: 'tenant-1', barcode: '   '),
      );

      expect(result, isNull);
      expect(gateway.lastBarcode, isNull);
    });
  });

  group('ProductListItemAssembler', () {
    test('scn_e01_u01_fr03_01 maps readiness blocker when price band missing', () {
      final row = ProductListItemReadRow(
        id: 'product-4',
        name: 'Vitamin B Complex',
        businessStatus: ProductBusinessStatus.active,
        facts: const ProductReadinessFacts(
          productId: 'product-4',
          productName: 'Vitamin B Complex',
          hasBaseUnit: true,
          hasImages: true,
          hasStock: true,
          hasBasePrice: true,
          hasPriceBand: false,
          hasRequiredCustomFields: true,
        ),
        updatedAt: DateTime.utc(2026, 3, 10),
      );

      final dto = ProductListItemAssembler.toDto(row);

      expect(dto.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        dto.readinessSummary.blockers.map((blocker) => blocker.code),
        contains(ReadinessBlockerCode.missingPriceBand),
      );
    });
  });

  group('GetProductControlCenterQueryHandler', () {
    test('scn_e01_u02_fr01_01 returns profile summary', () async {
      final gateway = _FakeCatalogReadGateway()..controlCenterResult = _sampleControlCenterModel();
      final handler = GetProductControlCenterQueryHandler(
        readGateway: gateway,
        permissionChecker: FakePermissionChecker(),
      );

      final result = await handler.handle(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.profile.name, 'Amoxicillin 500mg');
      expect(result.profile.sku, 'SP0001');
      expect(result.profile.images, isNotEmpty);
    });

    test('scn_e01_u02_fr02_01 returns operational cards', () async {
      final gateway = _FakeCatalogReadGateway()
        ..controlCenterResult = _sampleControlCenterModel(hasPriceBand: true);
      final handler = GetProductControlCenterQueryHandler(
        readGateway: gateway,
        permissionChecker: FakePermissionChecker(),
      );

      final result = await handler.handle(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.units.baseUnitName, 'Hộp');
      expect(result.stock.quantity, 150);
      expect(result.basePrice.amount, 80000);
      expect(result.priceBand.listBeforeVat, 120000);
    });

    test('shows a pending custom config while readiness stays incomplete', () async {
      final gateway = _FakeCatalogReadGateway()
        ..controlCenterResult = _sampleControlCenterModel(
          hasBasePrice: false,
          hasPendingCustomConfig: true,
        );
      final handler = GetProductControlCenterQueryHandler(
        readGateway: gateway,
        permissionChecker: FakePermissionChecker(),
      );

      final result = await handler.handle(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.priceBand.isMissing, isFalse);
      expect(result.priceBand.isPendingCalculation, isTrue);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.map((blocker) => blocker.code),
        containsAll(<String>[
          ReadinessBlockerCode.missingPrice,
          ReadinessBlockerCode.missingPriceBand,
        ]),
      );
    });

    test('scn_e01_u02_fr03_01 returns empty custom field cards', () async {
      final gateway = _FakeCatalogReadGateway()..controlCenterResult = _sampleControlCenterModel();
      final handler = GetProductControlCenterQueryHandler(
        readGateway: gateway,
        permissionChecker: FakePermissionChecker(),
      );

      final result = await handler.handle(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.customFieldGroupCards, isEmpty);
      expect(result.checklist, isEmpty);
    });

    test('scn_e01_u02_fr05_01 suggests set_price_band when missing band', () async {
      final gateway = _FakeCatalogReadGateway()
        ..controlCenterResult = _sampleControlCenterModel(hasPriceBand: false);
      final handler = GetProductControlCenterQueryHandler(
        readGateway: gateway,
        permissionChecker: FakePermissionChecker(),
      );

      final result = await handler.handle(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(
        result.contextualActions.map((action) => action.actionId),
        contains(ContextualActionId.setPriceBand),
      );
    });

    test('scn_e01_u02_fr06_01 includes history when view_history granted', () async {
      final gateway = _FakeCatalogReadGateway()..controlCenterResult = _sampleControlCenterModel();
      final handler = GetProductControlCenterQueryHandler(
        readGateway: gateway,
        permissionChecker: FakePermissionChecker(),
      );

      final result = await handler.handle(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.changeHistoryPreview, isNotEmpty);
      expect(result.changeHistoryPreview.first.changeType, ProductChangeHistoryAction.created);
    });

    test('scn_e01_u02_fr06_01 hides history without view_history permission', () async {
      final gateway = _FakeCatalogReadGateway()..controlCenterResult = _sampleControlCenterModel();
      final handler = GetProductControlCenterQueryHandler(
        readGateway: gateway,
        permissionChecker: FakePermissionChecker(
          deny: {CatalogPermissions.viewHistory},
        ),
      );

      final result = await handler.handle(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.changeHistoryPreview, isEmpty);
    });

    test('throws when product not found', () async {
      final handler = GetProductControlCenterQueryHandler(
        readGateway: _FakeCatalogReadGateway(),
        permissionChecker: FakePermissionChecker(),
      );

      await expectLater(
        handler.handle(
          GetProductControlCenterQuery(
            tenantId: 'tenant-1',
            productId: 'missing',
          ),
        ),
        throwsA(isA<ApplicationException>()),
      );
    });
  });
}
