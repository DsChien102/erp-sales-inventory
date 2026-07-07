import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingCatalogReadGateway implements ICatalogReadGateway {
  String? lastTenantId;
  ProductSearchCriteria? lastCriteria;
  int? lastLimit;
  int? lastOffset;
  int? lastMaxOptionsPerField;

  ProductSearchResultDto searchResult = ProductSearchResultDto(
    items: [
      ProductListItemDto(
        id: 'product-1',
        name: 'Amoxicillin',
        businessStatus: ProductStatus.active,
        readinessSummary: const ReadinessSummaryDto(
          status: ReadinessStatus.incomplete,
        ),
        customFieldValues: const [
          CustomFieldListValueDto(
            fieldId: 'field-1',
            groupId: 'group-1',
            groupName: 'Thông tin thuốc',
            fieldName: 'Dạng dùng',
            fieldType: 'singleSelect',
            displayValue: 'Dung dịch',
            sortOrder: 10,
          ),
        ],
        updatedAt: DateTime.utc(2026, 7, 7),
      ),
    ],
    totalCount: 1,
  );

  List<CustomFieldFilterOptionDto> filterOptionsResult = const [
    CustomFieldFilterOptionDto(
      fieldId: 'field-1',
      groupId: 'group-1',
      groupName: 'Thông tin thuốc',
      fieldName: 'Dạng dùng',
      fieldType: 'singleSelect',
      options: [],
      sortOrder: 10,
    ),
  ];

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
    throw UnimplementedError();
  }

  @override
  Future<ProductControlCenterReadModel?> loadControlCenter({
    required String tenantId,
    required String productId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    required String tenantId,
    required int maxOptionsPerField,
  }) async {
    lastTenantId = tenantId;
    lastMaxOptionsPerField = maxOptionsPerField;
    return filterOptionsResult;
  }
}

final class _RecordingCustomFieldReadGateway implements ICatalogCustomFieldReadGateway {
  String? lastTenantId;
  List<String>? lastProductIds;
  bool? lastIncludeInactiveValues;

  ProductCustomFieldSnapshotDto snapshotResult = const ProductCustomFieldSnapshotDto(
    products: {
      'product-1': [
        ProductCustomFieldSnapshotFieldDto(
          productId: 'product-1',
          fieldId: 'field-1',
          groupId: 'group-1',
          groupName: 'Thông tin thuốc',
          fieldName: 'Dạng dùng',
          fieldType: 'singleSelect',
          displayValue: 'Dung dịch',
          isActive: true,
        ),
      ],
    },
  );

  @override
  Future<ProductCustomFieldSnapshotDto> getSnapshot({
    required String tenantId,
    required List<String> productIds,
    required bool includeInactiveValues,
  }) async {
    lastTenantId = tenantId;
    lastProductIds = productIds;
    lastIncludeInactiveValues = includeInactiveValues;
    return snapshotResult;
  }
}

void main() {
  group('custom field search handlers', () {
    late _RecordingCatalogReadGateway readGateway;
    late _RecordingCustomFieldReadGateway customFieldReadGateway;

    setUp(() {
      readGateway = _RecordingCatalogReadGateway();
      customFieldReadGateway = _RecordingCustomFieldReadGateway();
    });

    test('scn_e03_u03_fr01_01 search returns custom field list values', () async {
      final handler = SearchProductsQueryHandler(readGateway: readGateway);

      final result = await handler.handle(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(),
          limit: 20,
          offset: 0,
        ),
      );

      expect(readGateway.lastTenantId, 'tenant-1');
      expect(result.items.single.customFieldValues.single.displayValue, 'Dung dịch');
    });

    test('scn_e03_u03_fr02_01 search passes keyword to gateway', () async {
      final handler = SearchProductsQueryHandler(readGateway: readGateway);

      await handler.handle(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(keyword: 'tiêu hóa'),
          limit: 20,
          offset: 0,
        ),
      );

      expect(readGateway.lastCriteria?.keyword, 'tiêu hóa');
    });

    test('scn_e03_u03_fr03_01 list filter options delegates to gateway', () async {
      final handler = ListCustomFieldFilterOptionsQueryHandler(
        readGateway: readGateway,
      );

      final result = await handler.handle(
        ListCustomFieldFilterOptionsQuery(
          tenantId: 'tenant-1',
          maxOptionsPerField: 25,
        ),
      );

      expect(readGateway.lastTenantId, 'tenant-1');
      expect(readGateway.lastMaxOptionsPerField, 25);
      expect(result.single.fieldName, 'Dạng dùng');
    });

    test('scn_e03_u03_fr03_02 search passes custom field filters to gateway', () async {
      final handler = SearchProductsQueryHandler(readGateway: readGateway);

      await handler.handle(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(
            customFieldFilters: [
              CustomFieldFilterCriteria(
                fieldId: 'field-1',
                optionId: 'opt-1',
              ),
            ],
          ),
          limit: 20,
          offset: 0,
        ),
      );

      expect(readGateway.lastCriteria?.customFieldFilters.single.optionId, 'opt-1');
    });

    test('scn_e03_u03_fr04_01 snapshot query delegates to custom field read gateway', () async {
      final handler = GetProductCustomFieldSnapshotQueryHandler(
        readGateway: customFieldReadGateway,
      );

      final result = await handler.handle(
        GetProductCustomFieldSnapshotQuery(
          tenantId: 'tenant-1',
          productIds: ['product-1'],
          includeInactiveValues: true,
        ),
      );

      expect(customFieldReadGateway.lastTenantId, 'tenant-1');
      expect(customFieldReadGateway.lastProductIds, ['product-1']);
      expect(customFieldReadGateway.lastIncludeInactiveValues, isTrue);
      expect(result.products['product-1']!.single.displayValue, 'Dung dịch');
    });

    test('list filter options validator rejects invalid maxOptionsPerField', () async {
      final validator = ListCustomFieldFilterOptionsQueryValidator();

      expect(
        () => validator.validate(
          ListCustomFieldFilterOptionsQuery(
            tenantId: 'tenant-1',
            maxOptionsPerField: 0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('snapshot validator rejects empty product ids', () async {
      final validator = GetProductCustomFieldSnapshotQueryValidator();

      expect(
        () => validator.validate(
          GetProductCustomFieldSnapshotQuery(
            tenantId: 'tenant-1',
            productIds: const [],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
