// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/data/models/catalog_enums.dart' as app_enum;
import 'package:erp/features/catalog/data/models/product_control_center.dart' as app_pcc;
import 'package:erp/features/catalog/data/models/product_inputs.dart' as app_in;
import 'package:erp/features/catalog/data/models/product_search.dart' as app_search;
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/product_reference_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/domain/custom_fields/custom_field_rpc_mapper.dart';
import 'package:vet45_catalog_infrastructure/src/domain/lifecycle/product_change_history_rpc_mapper.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/catalog_sales_lookup_rpc_mapper.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/product_rpc_mapper.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/product_control_center_mapper.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/product_readiness_facts_mapper.dart';

class _RecordingDuplicateChecker implements IProductDuplicateChecker {
  Object? capturedTenantId;
  Sku? capturedSku;
  Barcode? capturedBarcode;
  ProductId? capturedExcludeId;

  @override
  Future<List<ProductDuplicateMatch>> findMatches({
    required covariant dynamic tenantId,
    Sku? sku,
    Barcode? barcode,
    ProductId? excludeProductId,
  }) async {
    capturedTenantId = tenantId;
    capturedSku = sku;
    capturedBarcode = barcode;
    capturedExcludeId = excludeProductId;
    return const [];
  }
}

const tenantId = 'tenant-123';
const actorId = 'actor-456';
const storeId = 'store-789';
const productId = '11111111-1111-4111-8111-111111111111';

final _expectedSearchProductsParams = {
  'p_tenant_id': tenantId,
  'p_keyword': 'paracetamol',
  'p_business_statuses': ['active', 'inactive'],
  'p_readiness_filter': 'ready_to_sell',
  'p_include_soft_deleted': true,
  'p_limit': 50,
  'p_offset': 0,
  'p_custom_field_filters': [
    {'field_id': 'f1', 'option_id': 'opt-1'},
    {'field_id': 'f2', 'boolean_value': true},
  ],
  'p_sort_order': 'relevance_desc',
};

final _expectedListCustomFieldFilterOptionsParams = {
  'p_tenant_id': tenantId,
  'p_max_options_per_field': 50,
};

final _expectedCheckDuplicateCodesParams = {
  'p_tenant_id': tenantId,
  'p_sku': 'AB-1',
  'p_barcode': '893123',
  'p_exclude_product_id': 'prod-99',
};

final _expectedCheckDuplicateCodesBlankParams = {
  'p_tenant_id': tenantId,
  'p_sku': null,
  'p_barcode': null,
  'p_exclude_product_id': null,
};

final _expectedRequestProductImageUploadParams = {
  'p_tenant_id': tenantId,
  'p_file_name': 'test.png',
  'p_content_type': 'image/png',
  'p_byte_size': 1024,
  'p_actor_id': actorId,
};

final _expectedRequestMaintenanceImageUploadParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_file_name': 'test.png',
  'p_content_type': 'image/png',
  'p_byte_size': 1024,
  'p_actor_id': actorId,
};

final _expectedGetControlCenterParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
};

final _expectedGetReadinessParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
};

final _expectedUpdateProfileParams = {
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_product_id': productId,
  'p_name': 'Paracetamol 500',
  'p_trade_name': 'Hapacol',
  'p_sku': 'HAPA-500',
  'p_barcode': '893000111',
  'p_description': 'Giam dau',
  'p_note': 'Khong dung cho tre em',
  'p_expected_version': 2,
};

final _expectedUpdateImagesParams = {
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_product_id': productId,
  'p_images': [
    {
      'image_id': 'img-1',
      'storage_key': 'k1',
      'slot_id': 's1',
      'url': 'https://img',
      'is_primary': true,
      'sort_order': 0,
    },
  ],
  'p_expected_version': 2,
};

final _expectedDeactivateParams = {
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_product_id': productId,
  'p_reason': 'Het han',
  'p_expected_version': 2,
  'p_confirm_acknowledge_warnings': true,
};

final _expectedReactivateParams = {
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_product_id': productId,
  'p_reason': 'Nhap hang moi',
  'p_expected_version': 3,
};

final _expectedCheckDeletionEligibilityParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
};

final _expectedDeleteParams = {
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_product_id': productId,
  'p_reason': 'Ngung kinh doanh',
  'p_expected_version': 4,
  'p_confirm_acknowledge_warnings': false,
};

final _expectedRestoreParams = {
  'p_tenant_id': tenantId,
  'p_actor_id': actorId,
  'p_product_id': productId,
  'p_reason': 'Phuc hoi san pham',
  'p_expected_version': 5,
};

final _expectedGetChangeHistoryParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_limit': 20,
  'p_offset': 10,
  'p_categories': ['profile', 'pricing'],
};

final _expectedSearchSellableParams = {
  'p_tenant_id': tenantId,
  'p_store_id': storeId,
  'p_keyword': 'para',
  'p_limit': 20,
  'p_offset': 0,
};

final _expectedResolveSellableBarcodeParams = {
  'p_tenant_id': tenantId,
  'p_store_id': storeId,
  'p_barcode': '893123456',
};

final _expectedListSellableUnitsParams = {
  'p_tenant_id': tenantId,
  'p_store_id': storeId,
  'p_product_id': productId,
};

final _expectedResolveSellableProductsParams = {
  'p_tenant_id': tenantId,
  'p_store_id': storeId,
  'p_product_ids': ['prod-1', 'prod-2'],
};

void main() {
  group('product_rpc_parity', () {
    group('old (mappers)', () {
      test('H1 1: search_products params', () {
        final criteria = ProductSearchCriteria(
          keyword: 'paracetamol',
          businessStatuses: {ProductBusinessStatus.active, ProductBusinessStatus.inactive},
          readinessFilter: ProductReadinessFilter.readyToSell,
          customFieldFilters: [
            CustomFieldFilterCriteria(fieldId: 'f1', optionId: 'opt-1'),
            CustomFieldFilterCriteria(fieldId: 'f2', booleanValue: true),
          ],
          sortOrder: ProductSortOrder.relevanceDesc,
          includeSoftDeleted: true,
        );

        final params = ProductRpcMapper.searchProductsParams(
          tenantId: tenantId,
          criteria: criteria,
          limit: 50,
          offset: 0,
        );

        expect(params, _expectedSearchProductsParams);
      });

      test('H1 2: list_custom_field_filter_options params', () {
        final params = CustomFieldRpcMapper.listCustomFieldFilterOptionsParams(
          tenantId: tenantId,
          maxOptionsPerField: 50,
        );

        expect(params, _expectedListCustomFieldFilterOptionsParams);
      });

      test('H1 3 & H8: check_duplicate_product_code params with SKU uppercase and trim', () async {
        final checker = _RecordingDuplicateChecker();
        final handler = CheckDuplicateProductCodeQueryHandler(duplicateChecker: checker);

        await handler.handle(CheckDuplicateProductCodeQuery(
          tenantId: tenantId,
          sku: ' ab-1 ',
          barcode: ' 893123 ',
          excludeProductId: 'prod-99',
        ));
        expect(checker.capturedSku?.value, 'AB-1');
        expect(checker.capturedBarcode?.value, '893123');
        expect(checker.capturedExcludeId?.value, 'prod-99');

        final params = ProductRpcMapper.checkDuplicateParams(
          tenantId: tenantId,
          sku: checker.capturedSku?.value,
          barcode: checker.capturedBarcode?.value,
          excludeProductId: checker.capturedExcludeId?.value,
        );
        expect(params, _expectedCheckDuplicateCodesParams);

        await handler.handle(CheckDuplicateProductCodeQuery(
          tenantId: tenantId,
          sku: '   ',
          barcode: '   ',
        ));
        expect(checker.capturedSku, isNull);
        expect(checker.capturedBarcode, isNull);

        final paramsBlank = ProductRpcMapper.checkDuplicateParams(
          tenantId: tenantId,
          sku: checker.capturedSku?.value,
          barcode: checker.capturedBarcode?.value,
        );
        expect(paramsBlank, _expectedCheckDuplicateCodesBlankParams);
      });

      test('H1 4: create_guided_product params', () {
        final cmd = CreateGuidedProductCommand(
          id: productId,
          tenantId: tenantId,
          actorId: actorId,
          productName: '  Thuốc hạ sốt  ',
          commercialName: '  Panadol  ',
          sku: '  PANA-01  ',
          barcode: '  893123456  ',
          note: '  Ghi chú  ',
          images: const [
            ProductImageInput(
              storageKey: 'img-key-1',
              slotId: 'slot-1',
              url: 'https://img',
              isPrimary: true,
              sortOrder: 0,
            ),
          ],
          baseUnit: const NewTenantUnit('Hộp'),
          basicStockQuantityBase: 100,
          basePrice: 50000.0,
          listBeforeVat: 60000,
          floorBeforeVat: 55000,
          useStorePriceRule: false,
          priceBandSourceType: PriceBandSourceType.customConfig,
          listMarkupRatio: 1.2,
          floorMarkupRatio: 1.1,
          customFieldValues: const [
            ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'Ghi chú thêm'),
          ],
        );

        final params = ProductRpcMapper.createGuidedProductParams(cmd);

        expect(params['p_tenant_id'], tenantId);
        expect(params['p_actor_id'], actorId);
        expect(params['p_name'], 'Thuốc hạ sốt');
        expect(params['p_trade_name'], 'Panadol');
        expect(params['p_sku'], 'PANA-01');
        expect(params['p_barcode'], '893123456');
        expect(params['p_note'], 'Ghi chú');
        expect(params['p_images'], [
          {
            'storage_key': 'img-key-1',
            'slot_id': 'slot-1',
            'url': 'https://img',
            'is_primary': true,
            'sort_order': 0,
          },
        ]);
        expect(params['p_tenant_unit_id'], isNull);
        expect(params['p_new_unit_name'], 'Hộp');
        expect(params['p_basic_stock_quantity_base'], 100);
        expect(params['p_base_price_after_vat'], 50000.0);
        expect(params['p_list_price_before_vat'], 60000);
        expect(params['p_floor_price_before_vat'], 55000);
        expect(params['p_use_store_price_rule'], isFalse);
        expect(params['p_price_band_source_type'], 'customConfig');
        expect(params['p_list_markup_ratio'], 1.2);
        expect(params['p_floor_markup_ratio'], 1.1);
        expect(params['p_custom_field_values'], [
          {
            'field_id': 'f1',
            'text_value': 'Ghi chú thêm',
            'number_value': null,
            'date_value': null,
            'boolean_value': null,
            'option_id': null,
          },
        ]);
        expect(params['p_idempotency_key'], productId);
        expect(params['p_reference_id'], ProductReferenceId.fromProductId(ProductId(productId)).value);
      });

      test('H1 5: request_product_image_upload params', () {
        // Gateway cũ cần SupabaseClient thật; hành vi được kiểm ở H9 nhóm new
      }, skip: 'Gateway cũ SupabaseProductImageUploadGateway cần SupabaseClient thật; kiểm ở H9 nhóm new');

      test('H1 6: request_product_maintenance_image_upload params', () {
        final cmd = RequestProductMaintenanceImageUploadCommand(
          tenantId: tenantId,
          productId: productId,
          fileName: 'test.png',
          contentType: 'image/png',
          byteSize: 1024,
          actorId: actorId,
        );
        final params = ProductRpcMapper.requestMaintenanceImageUploadParams(cmd);

        expect(params, _expectedRequestMaintenanceImageUploadParams);
      });

      test('H1 7: get_product_control_center params', () {
        final params = ProductRpcMapper.getProductControlCenterParams(
          tenantId: tenantId,
          productId: productId,
        );
        expect(params, _expectedGetControlCenterParams);
      });

      test('H1 8: get_product_readiness params', () {
        final params = ProductRpcMapper.getProductReadinessParams(
          tenantId: tenantId,
          productId: productId,
        );
        expect(params, _expectedGetReadinessParams);
      });

      test('H1 9: update_product_profile params', () {
        final cmd = UpdateProductProfileCommand(
          tenantId: tenantId,
          actorId: actorId,
          productId: productId,
          productName: '  Paracetamol 500  ',
          commercialName: '  Hapacol  ',
          sku: '  HAPA-500  ',
          barcode: '  893000111  ',
          description: '  Giam dau  ',
          note: '  Khong dung cho tre em  ',
          expectedVersion: 2,
        );
        final params = ProductRpcMapper.updateProductProfileParams(cmd);

        expect(params, _expectedUpdateProfileParams);
      });

      test('H1 10: update_product_images params', () {
        final cmd = UpdateProductImagesCommand(
          tenantId: tenantId,
          actorId: actorId,
          productId: productId,
          expectedVersion: 2,
          images: const [
            ProductImageMutationInput(
              imageId: 'img-1',
              storageKey: 'k1',
              slotId: 's1',
              url: 'https://img',
              isPrimary: true,
              sortOrder: 0,
            ),
          ],
        );
        final params = ProductRpcMapper.updateProductImagesParams(cmd);

        expect(params, _expectedUpdateImagesParams);
      });

      test('H1 11: deactivate_product params', () {
        final cmd = DeactivateProductCommand(
          tenantId: tenantId,
          actorId: actorId,
          productId: productId,
          expectedVersion: 2,
          reason: '  Het han  ',
          confirmAcknowledgeWarnings: true,
        );
        final params = ProductRpcMapper.deactivateProductParams(cmd);

        expect(params, _expectedDeactivateParams);
      });

      test('H1 12: reactivate_product params', () {
        final cmd = ReactivateProductCommand(
          tenantId: tenantId,
          actorId: actorId,
          productId: productId,
          expectedVersion: 3,
          reason: '  Nhap hang moi  ',
        );
        final params = ProductRpcMapper.reactivateProductParams(cmd);

        expect(params, _expectedReactivateParams);
      });

      test('H1 13: check_product_deletion_eligibility params', () {
        final qry = CheckProductDeletionEligibilityQuery(
          tenantId: tenantId,
          productId: productId,
        );
        final params = ProductRpcMapper.checkProductDeletionEligibilityParams(qry);

        expect(params, _expectedCheckDeletionEligibilityParams);
      });

      test('H1 14: delete_product params', () {
        final cmd = DeleteProductCommand(
          tenantId: tenantId,
          actorId: actorId,
          productId: productId,
          expectedVersion: 4,
          reason: '  Ngung kinh doanh  ',
          confirmAcknowledgeWarnings: false,
        );
        final params = ProductRpcMapper.deleteProductParams(cmd);

        expect(params, _expectedDeleteParams);
      });

      test('H1 15: restore_product params', () {
        final cmd = RestoreProductCommand(
          tenantId: tenantId,
          actorId: actorId,
          productId: productId,
          expectedVersion: 5,
          reason: '  Phuc hoi san pham  ',
        );
        final params = ProductRpcMapper.restoreProductParams(cmd);

        expect(params, _expectedRestoreParams);
      });

      test('H1 16: get_product_change_history params', () {
        final params = ProductChangeHistoryRpcMapper.getProductChangeHistoryParams(
          tenantId: tenantId,
          productId: productId,
          limit: 20,
          offset: 10,
          changeCategories: const [
            ProductChangeCategory.profile,
            ProductChangeCategory.pricing,
          ],
        );

        expect(params, _expectedGetChangeHistoryParams);
      });

      test('H1 17: search_sellable_products params', () {
        final params = CatalogSalesLookupRpcMapper.searchSellableProductsParams(
          tenantId: tenantId,
          storeId: storeId,
          keyword: 'para',
          limit: 20,
          offset: 0,
        );

        expect(params, _expectedSearchSellableParams);
      });

      test('H1 18: resolve_sellable_barcode params', () {
        final params = CatalogSalesLookupRpcMapper.resolveSellableBarcodeParams(
          tenantId: tenantId,
          storeId: storeId,
          barcode: '893123456',
        );

        expect(params, _expectedResolveSellableBarcodeParams);
      });

      test('H1 19: list_sellable_product_units params', () {
        final params = CatalogSalesLookupRpcMapper.listSellableProductUnitsParams(
          tenantId: tenantId,
          storeId: storeId,
          productId: productId,
        );

        expect(params, _expectedListSellableUnitsParams);
      });

      test('H1 20: resolve_sellable_products params', () {
        final params = CatalogSalesLookupRpcMapper.resolveSellableProductsParams(
          tenantId: tenantId,
          storeId: storeId,
          productIds: const ['prod-1', 'prod-2'],
        );

        expect(params, _expectedResolveSellableProductsParams);
      });

      test('H2: results mapping parity', () {
        // 1. checkDuplicateCodes row
        final dupField = ProductRpcMapper.duplicateFieldFromRpc('sku');
        expect(dupField, ProductDuplicateField.sku);

        // 2. createGuided row
        final guidedResult = ProductRpcMapper.createGuidedProductResultFromJson({
          'product_id': 'p1',
          'readiness_status': 'ready_to_sell',
          'readiness_blockers': <Map<String, dynamic>>[],
        });
        expect(guidedResult.productId, 'p1');
        expect(guidedResult.readinessSummary.status, ReadinessStatus.readyToSell);

        // 3. checkDeletionEligibility row
        final delResult = ProductRpcMapper.productDeletionEligibilityFromRow({
          'product_id': 'p1',
          'can_delete': false,
          'issues': [
            {'code': 'has_stock', 'message': 'Còn hàng', 'severity': 'blocker'},
          ],
          'suggested_action_id': 'open_inventory',
        });
        expect(delResult.canDelete, isFalse);
        expect(delResult.blockers.length, 1);
        expect(delResult.blockers.first.message, 'Còn hàng');
        expect(delResult.suggestedActionId, 'open_inventory');

        // 4. change history
        final histPage = ProductChangeHistoryRpcMapper.pageFromJson({
          'items': [
            {
              'id': 'h1',
              'occurred_at': '2026-01-01T00:00:00.000Z',
              'actor_display_name': 'Tester',
              'change_type': 'product_created',
              'summary': 'Tạo sản phẩm',
              'change_category': 'profile',
              'source': 'user',
              'is_sensitive_masked': false,
            },
          ],
          'total_count': 1,
        });
        expect(histPage.items.length, 1);
        expect(histPage.items.first.summary, 'Tạo sản phẩm');

        // 5. control center row unwrap
        final ccJson = {
          'product_id': 'p1',
          'name': 'P1',
          'business_status': 'active',
          'has_base_unit': true,
          'has_images': false,
          'has_stock': true,
          'has_base_price': true,
          'has_price_band': true,
          'has_required_custom_fields': true,
          'stock_qty': 10,
          'base_unit_name': 'Hộp',
        };
        final ccModel = ProductControlCenterMapper.fromJson(ccJson);
        expect(ccModel.name, 'P1');
        expect(ccModel.facts.hasBaseUnit, isTrue);

        // R1-1: old mapper with customConfig -> priceBandSourceType == null and missingMessage == 'Thiếu khung giá bán'
        final oldModel = ProductControlCenterMapper.fromJson({
          ...ccJson,
          'price_band_source_type': 'customConfig',
        });
        expect(oldModel.priceBandSourceType, isNull);
        final oldDto = ProductControlCenterAssembler.assemble(
          model: oldModel,
          permissions: const ProductReadinessPermissionContext(
            canManageUnits: true,
            canManageStock: true,
            canManagePricing: true,
            canUpdateProduct: true,
            canCreateProduct: true,
            canViewDetail: true,
          ),
        );
        expect(oldDto.priceBand.sourceType, isNull);
        expect(oldDto.priceBand.missingMessage, 'Thiếu khung giá bán');

        // 6. readiness facts row
        final facts = ProductReadinessFactsMapper.fromRow({
          'product_id': 'p1',
          'product_name': 'P1',
          'has_base_unit': true,
          'has_images': false,
          'has_stock': false,
          'has_base_price': false,
          'has_price_band': false,
          'has_required_custom_fields': true,
          'stock_mode': 'basic',
          'base_price_mode': 'manual',
        });
        expect(facts.hasBaseUnit, isTrue);
        expect(facts.hasImages, isFalse);

        // 7. list custom field filter options
        final opts = CustomFieldRpcMapper.filterOptionsFromJson([
          {
            'field_id': 'f1',
            'group_id': 'g1',
            'group_name': 'nhóm 1',
            'field_name': 'trường 1',
            'field_type': 'single_select',
            'sort_order': 1,
            'options': [
              {
                'option_id': 'opt1',
                'label': 'Lựa chọn 1',
                'sort_order': 1,
                'is_active': true,
              },
            ],
          },
        ]);
        expect(opts.length, 1);
        expect(opts.first.groupName, 'Nhóm 1');
        expect(opts.first.options.length, 1);

        // 8. search sellable products
        const validUuid = '11111111-1111-4111-8111-111111111111';
        const unitUuid = '22222222-2222-4222-8222-222222222222';
        final sellableProducts = CatalogSalesLookupRpcMapper.productsFromPayload({
          'items': [
            {
              'product_id': validUuid,
              'sku': 'SKU1',
              'display_name': 'SP 1',
              'is_sellable': true,
              'currency_code': 'VND',
              'list_price_minor': 10000,
              'units': [
                {
                  'product_unit_id': unitUuid,
                  'unit_code': 'HOP',
                  'unit_name': 'Hộp',
                  'is_default': true,
                  'is_active': true,
                  'is_sellable': true,
                  'list_price_minor': 10000,
                },
              ],
            },
          ],
        });
        expect(sellableProducts.length, 1);
        expect(sellableProducts.first.displayName, 'SP 1');

        // 9. resolve sellable products
        final resolutions = CatalogSalesLookupRpcMapper.resolutionsFromPayload({
          'items': [
            {
              'product_id': validUuid,
              'resolution': 'not_found',
            },
          ],
        });
        expect(resolutions.length, 1);
        expect(resolutions.first.resolution, SellableProductResolution.notFound);
      });
    });

    group('new (ProductRepository)', () {
      late _RecordingRpc rpc;
      late List<String> signedKeys;
      late ProductRepository repository;

      setUp(() {
        rpc = _RecordingRpc();
        signedKeys = [];
        repository = ProductRepository(
          rpc: rpc,
          tenantId: () async => tenantId,
          actorId: () async => actorId,
          hasPermission: (p) => true,
          signUploadUrl: (key) async {
            signedKeys.add(key);
            return 'https://signed/$key';
          },
        );
      });

      test('H1 1: search_products params & mapping', () async {
        rpc.nextRowsResult = [
          {
            'product_id': productId,
            'name': 'Paracetamol',
            'trade_name': 'Panadol',
            'sku': 'PANA-01',
            'business_status': 'active',
            'has_base_unit': true,
            'has_images': false,
            'has_stock': true,
            'has_base_price': true,
            'has_price_band': true,
            'has_required_custom_fields': true,
            'updated_at': '2026-01-01T00:00:00.000Z',
            'total_count': 100,
            'ready_to_sell_count': 80,
            'incomplete_count': 15,
            'inactive_count': 5,
          },
        ];

        final criteria = app_search.ProductSearchCriteria(
          keyword: 'paracetamol',
          businessStatuses: {app_enum.ProductBusinessStatus.active, app_enum.ProductBusinessStatus.inactive},
          readinessFilter: app_enum.ProductReadinessFilter.readyToSell,
          customFieldFilters: const [
            app_search.CustomFieldFilterCriteria(fieldId: 'f1', optionId: 'opt-1'),
            app_search.CustomFieldFilterCriteria(fieldId: 'f2', booleanValue: true),
          ],
          sortOrder: app_enum.ProductSortOrder.relevanceDesc,
          includeSoftDeleted: true,
        );

        final result = await repository.search(criteria: criteria, limit: 50, offset: 0);

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.schema, 'catalog');
        expect(rpc.calls.first.rpc, 'search_products');
        expect(rpc.calls.first.params, _expectedSearchProductsParams);

        expect(result.items.length, 1);
        expect(result.items.first.id, productId);
        expect(result.totalCount, 100);
        expect(result.readyToSellCount, 80);
        expect(result.incompleteCount, 15);
        expect(result.inactiveCount, 5);
      });

      test('search_products missing total_count defaults to items.length', () async {
        rpc.nextRowsResult = [
          {
            'product_id': productId,
            'name': 'Paracetamol',
            'updated_at': '2026-01-01T00:00:00.000Z',
          },
        ];

        final result = await repository.search(criteria: app_search.ProductSearchCriteria());
        expect(result.items.length, 1);
        expect(result.totalCount, 1);
      });

      test('H1 2: list_custom_field_filter_options params & mapping', () async {
        rpc.nextCallResult = [
          {
            'field_id': 'f1',
            'group_id': 'g1',
            'group_name': 'nhóm 1',
            'field_name': 'trường 1',
            'field_type': 'single_select',
            'sort_order': 1,
            'options': [
              {
                'option_id': 'opt1',
                'label': 'Lựa chọn 1',
                'sort_order': 1,
                'is_active': true,
              },
            ],
          },
        ];

        final result = await repository.listCustomFieldFilterOptions(maxOptionsPerField: 50);

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'list_custom_field_filter_options');
        expect(rpc.calls.first.params, _expectedListCustomFieldFilterOptionsParams);
        expect(result.length, 1);
        expect(result.first.groupName, 'Nhóm 1');
      });

      test('H1 3 & H8: check_duplicate_product_code params with SKU uppercase and trim', () async {
        rpc.nextRowsResult = [
          {
            'duplicate_field': 'sku',
            'product_id': 'p-dup',
            'product_name': 'Dup Product',
            'matched_value': 'AB-1',
          },
        ];

        final result = await repository.checkDuplicateCodes(
          sku: ' ab-1 ',
          barcode: ' 893123 ',
          excludeProductId: 'prod-99',
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'check_duplicate_product_code');
        expect(rpc.calls.first.params, _expectedCheckDuplicateCodesParams);
        expect(result.length, 1);
        expect(result.first.field, app_enum.ProductDuplicateField.sku);
        expect(result.first.matchedValue, 'AB-1');

        // Blank SKU/barcode -> null
        rpc.calls.clear();
        rpc.nextRowsResult = [];
        await repository.checkDuplicateCodes(sku: '   ', barcode: '   ');
        expect(rpc.calls.first.params, _expectedCheckDuplicateCodesBlankParams);
      });

      test('H1 4: create_guided_product params & referenceId from idempotencyKey', () async {
        rpc.nextCallResult = {
          'product_id': 'p-new',
          'readiness_status': 'ready_to_sell',
          'readiness_blockers': <Map<String, dynamic>>[],
        };

        const input = app_in.CreateGuidedProductInput(
          productName: '  Thuốc hạ sốt  ',
          commercialName: '  Panadol  ',
          sku: '  PANA-01  ',
          barcode: '  893123456  ',
          note: '  Ghi chú  ',
          images: [
            app_in.ProductImageInput(
              storageKey: 'img-key-1',
              slotId: 'slot-1',
              url: 'https://img',
              isPrimary: true,
              sortOrder: 0,
            ),
          ],
          baseUnit: app_in.NewTenantUnit('Hộp'),
          basicStockQuantityBase: 100,
          basePrice: 50000.0,
          listBeforeVat: 60000,
          floorBeforeVat: 55000,
          useStorePriceRule: false,
          priceBandSourceType: app_enum.PriceBandSourceType.customConfig,
          listMarkupRatio: 1.2,
          floorMarkupRatio: 1.1,
          customFieldValues: [
            app_in.ProductCustomFieldValueInput(fieldId: 'f1', textValue: 'Ghi chú thêm'),
          ],
        );

        final result = await repository.createGuided(input);

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'create_guided_product');
        final params = rpc.calls.first.params!;

        expect(params['p_tenant_id'], tenantId);
        expect(params['p_actor_id'], actorId);
        expect(params['p_name'], 'Thuốc hạ sốt');
        expect(params['p_trade_name'], 'Panadol');
        expect(params['p_sku'], 'PANA-01');
        expect(params['p_barcode'], '893123456');
        expect(params['p_note'], 'Ghi chú');
        expect(params['p_images'], [
          {
            'storage_key': 'img-key-1',
            'slot_id': 'slot-1',
            'url': 'https://img',
            'is_primary': true,
            'sort_order': 0,
          },
        ]);
        expect(params['p_tenant_unit_id'], isNull);
        expect(params['p_new_unit_name'], 'Hộp');
        expect(params['p_basic_stock_quantity_base'], 100);
        expect(params['p_base_price_after_vat'], 50000.0);
        expect(params['p_list_price_before_vat'], 60000);
        expect(params['p_floor_price_before_vat'], 55000);
        expect(params['p_use_store_price_rule'], isFalse);
        expect(params['p_price_band_source_type'], 'customConfig');
        expect(params['p_list_markup_ratio'], 1.2);
        expect(params['p_floor_markup_ratio'], 1.1);
        expect(params['p_custom_field_values'], [
          {
            'field_id': 'f1',
            'text_value': 'Ghi chú thêm',
            'number_value': null,
            'date_value': null,
            'boolean_value': null,
            'option_id': null,
          },
        ]);
        expect(params['p_idempotency_key'], isA<String>());
        final idempotencyKey = params['p_idempotency_key'] as String;
        expect(params['p_reference_id'], productReferenceIdFromUuid(idempotencyKey));

        expect(result.productId, 'p-new');
        expect(result.readinessSummary.status, app_enum.ReadinessStatus.readyToSell);
      });

      test('H1 5 & H9: request_product_image_upload slot & sign URL', () async {
        rpc.nextRowsResult = [
          {
            'slot_id': 'slot-abc',
            'storage_key': 'key-abc',
            'expires_at': '2026-05-01T00:00:00.000Z',
          },
        ];

        final slot = await repository.requestImageUpload(
          fileName: 'test.png',
          contentType: 'image/png',
          byteSize: 1024,
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'request_product_image_upload');
        expect(rpc.calls.first.params, _expectedRequestProductImageUploadParams);

        expect(slot.slotId, 'slot-abc');
        expect(slot.storageKey, 'key-abc');
        expect(slot.signedUploadUrl, 'https://signed/key-abc');
        expect(slot.expiresAt, DateTime.parse('2026-05-01T00:00:00.000Z').toUtc());
        expect(signedKeys, ['key-abc']);
      });

      test('H1 6 & H9: request_product_maintenance_image_upload slot & sign URL', () async {
        rpc.nextRowsResult = [
          {
            'slot_id': 'slot-m-1',
            'storage_key': 'key-m-1',
            'expires_at': '2026-05-01T00:00:00.000Z',
          },
        ];

        final slot = await repository.requestMaintenanceImageUpload(
          productId: productId,
          fileName: 'test.png',
          contentType: 'image/png',
          byteSize: 1024,
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'request_product_maintenance_image_upload');
        expect(rpc.calls.first.params, _expectedRequestMaintenanceImageUploadParams);

        expect(slot.slotId, 'slot-m-1');
        expect(slot.storageKey, 'key-m-1');
        expect(slot.signedUploadUrl, 'https://signed/key-m-1');
        expect(signedKeys, ['key-m-1']);
      });

      test('H1 7: get_product_control_center params, unwrapping, 5 cards & customConfig', () async {
        final ccRaw = {
          'product_id': productId,
          'name': 'P1',
          'business_status': 'active',
          'has_base_unit': true,
          'has_images': false,
          'has_stock': true,
          'has_base_price': true,
          'has_price_band': true,
          'has_required_custom_fields': true,
          'stock_qty': 10,
          'base_unit_name': 'Hộp',
          'price_band_source_type': 'customConfig',
        };
        rpc.nextRowsResult = [
          {
            'get_product_control_center': ccRaw,
          },
        ];

        final pccDto = await repository.getControlCenter(productId);

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'get_product_control_center');
        expect(rpc.calls.first.params, _expectedGetControlCenterParams);

        // 5 cards assertion
        expect(pccDto.profile.productId, productId);
        expect(pccDto.profile.name, 'P1');
        expect(pccDto.units.baseUnitName, 'Hộp');
        expect(pccDto.stock.quantity, 10);
        expect(pccDto.basePrice, isNotNull);
        expect(pccDto.priceBand, isNotNull);
        expect(pccDto.customFieldGroupCards, isA<List>());

        // R1-1: new model preserves customConfig and sets isPendingCalculation
        final readModel = app_pcc.ProductControlCenterReadModel.fromJson(ccRaw);
        expect(readModel.priceBandSourceType, app_enum.PriceBandSourceType.customConfig);
        expect(pccDto.priceBand.sourceType, app_enum.PriceBandSourceType.customConfig);
        expect(pccDto.priceBand.isPendingCalculation, isTrue);
        expect(pccDto.priceBand.missingMessage, isNull);

        // R1-2: empty rows -> PRODUCT_NOT_FOUND
        rpc.nextRowsResult = [];
        await expectLater(
          repository.getControlCenter(productId),
          throwsA(
            isA<AppException>().having((e) => e.code, 'code', CatalogErrorCodes.productNotFound),
          ),
        );
      });

      test('H1 8: get_product_readiness params, assemble & empty check', () async {
        rpc.nextRowsResult = [
          {
            'product_id': productId,
            'product_name': 'P1',
            'has_base_unit': true,
            'has_images': false,
            'has_stock': false,
            'has_base_price': false,
            'has_price_band': false,
            'has_required_custom_fields': true,
            'stock_mode': 'basic',
            'base_price_mode': 'manual',
          },
        ];

        final view = await repository.getReadiness(productId);

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'get_product_readiness');
        expect(rpc.calls.first.params, _expectedGetReadinessParams);

        expect(view.productId, productId);
        expect(view.readinessSummary.status, app_enum.ReadinessStatus.incomplete);

        // R1-2: empty rows -> PRODUCT_NOT_FOUND
        rpc.nextRowsResult = [];
        await expectLater(
          repository.getReadiness(productId),
          throwsA(
            isA<AppException>().having((e) => e.code, 'code', CatalogErrorCodes.productNotFound),
          ),
        );
      });

      test('H1 9 & H5: update_product_profile params (single RPC) & empty check', () async {
        rpc.nextRowsResult = [{'ok': true}];

        await repository.updateProfile(
          productId: productId,
          expectedVersion: 2,
          productName: '  Paracetamol 500  ',
          commercialName: '  Hapacol  ',
          sku: '  HAPA-500  ',
          barcode: '  893000111  ',
          description: '  Giam dau  ',
          note: '  Khong dung cho tre em  ',
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'update_product_profile');
        expect(rpc.calls.first.params, _expectedUpdateProfileParams);

        // R1-2: empty rows check
        rpc.nextRowsResult = [];
        await expectLater(
          repository.updateProfile(
            productId: productId,
            expectedVersion: 2,
            productName: 'Paracetamol',
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Product update did not return a result.'),
          ),
        );
      });

      test('H1 10 & H5: update_product_images params (single RPC) & empty check', () async {
        rpc.nextRowsResult = [{'ok': true}];

        await repository.updateImages(
          productId: productId,
          expectedVersion: 2,
          images: const [
            app_in.ProductImageMutationInput(
              imageId: 'img-1',
              storageKey: 'k1',
              slotId: 's1',
              url: 'https://img',
              isPrimary: true,
              sortOrder: 0,
            ),
          ],
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'update_product_images');
        expect(rpc.calls.first.params, _expectedUpdateImagesParams);

        // R1-2: empty rows check
        rpc.nextRowsResult = [];
        await expectLater(
          repository.updateImages(
            productId: productId,
            expectedVersion: 2,
            images: const [],
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Product image update did not return a result.'),
          ),
        );
      });

      test('H1 11 & H5: deactivate_product params (single RPC) & empty check', () async {
        rpc.nextRowsResult = [{'ok': true}];

        await repository.deactivate(
          productId: productId,
          expectedVersion: 2,
          reason: '  Het han  ',
          confirmAcknowledgeWarnings: true,
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'deactivate_product');
        expect(rpc.calls.first.params, _expectedDeactivateParams);

        // R1-2: empty rows check
        rpc.nextRowsResult = [];
        await expectLater(
          repository.deactivate(
            productId: productId,
            expectedVersion: 2,
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Product deactivate did not return a result.'),
          ),
        );
      });

      test('H1 12 & H5: reactivate_product params (single RPC) & empty check', () async {
        rpc.nextRowsResult = [{'ok': true}];

        await repository.reactivate(
          productId: productId,
          expectedVersion: 3,
          reason: '  Nhap hang moi  ',
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'reactivate_product');
        expect(rpc.calls.first.params, _expectedReactivateParams);

        // R1-2: empty rows check
        rpc.nextRowsResult = [];
        await expectLater(
          repository.reactivate(
            productId: productId,
            expectedVersion: 3,
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Product reactivate did not return a result.'),
          ),
        );
      });

      test('H1 13: check_product_deletion_eligibility params, DTO & empty check', () async {
        rpc.nextRowsResult = [
          {
            'product_id': productId,
            'can_delete': false,
            'issues': [
              {'code': 'has_stock', 'message': 'Còn hàng', 'severity': 'blocker'},
              {'code': 'has_recent_orders', 'message': 'Có đơn hàng gần đây', 'severity': 'warning'},
            ],
            'suggested_action_id': 'open_inventory',
          },
        ];

        final res = await repository.checkDeletionEligibility(productId);

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'check_product_deletion_eligibility');
        expect(rpc.calls.first.params, _expectedCheckDeletionEligibilityParams);
        expect(res.productId, productId);
        expect(res.canDelete, isFalse);
        expect(res.issues.length, 2);
        expect(res.blockers.length, 1);
        expect(res.blockers.first.code, 'has_stock');
        expect(res.blockers.first.message, 'Còn hàng');
        expect(res.warnings.length, 1);
        expect(res.warnings.first.code, 'has_recent_orders');
        expect(res.suggestedActionId, 'open_inventory');

        // R1-2: empty rows check
        rpc.nextRowsResult = [];
        await expectLater(
          repository.checkDeletionEligibility(productId),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Product deletion eligibility did not return a result.'),
          ),
        );
      });

      test('H1 14 & H5: delete_product params (single RPC) & empty check', () async {
        rpc.nextRowsResult = [{'ok': true}];

        await repository.delete(
          productId: productId,
          expectedVersion: 4,
          reason: '  Ngung kinh doanh  ',
          confirmAcknowledgeWarnings: false,
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'delete_product');
        expect(rpc.calls.first.params, _expectedDeleteParams);

        // R1-2: empty rows check
        rpc.nextRowsResult = [];
        await expectLater(
          repository.delete(
            productId: productId,
            expectedVersion: 4,
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Product delete did not return a result.'),
          ),
        );
      });

      test('H1 15 & H5: restore_product params (single RPC) & empty check', () async {
        rpc.nextRowsResult = [{'ok': true}];

        await repository.restore(
          productId: productId,
          expectedVersion: 5,
          reason: '  Phuc hoi san pham  ',
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'restore_product');
        expect(rpc.calls.first.params, _expectedRestoreParams);

        // R1-2: empty rows check
        rpc.nextRowsResult = [];
        await expectLater(
          repository.restore(
            productId: productId,
            expectedVersion: 5,
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Product restore did not return a result.'),
          ),
        );
      });

      test('H1 16: get_product_change_history params', () async {
        rpc.nextCallResult = {
          'items': [
            {
              'id': 'h1',
              'occurred_at': '2026-01-01T00:00:00.000Z',
              'actor_display_name': 'Tester',
              'change_type': 'product_created',
              'summary': 'Tạo sản phẩm',
              'change_category': 'profile',
              'source': 'user',
              'is_sensitive_masked': false,
            },
          ],
          'total_count': 1,
        };

        final res = await repository.getChangeHistory(
          productId: productId,
          limit: 20,
          offset: 10,
          changeCategories: const ['profile', 'pricing'],
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'get_product_change_history');
        expect(rpc.calls.first.params, _expectedGetChangeHistoryParams);
        expect(res.items.length, 1);
        expect(res.items.first.summary, 'Tạo sản phẩm');
      });

      test('H1 17: search_sellable_products params', () async {
        const validUuid = '11111111-1111-4111-8111-111111111111';
        const unitUuid = '22222222-2222-4222-8222-222222222222';
        rpc.nextCallResult = {
          'items': [
            {
              'product_id': validUuid,
              'sku': 'SKU1',
              'display_name': 'SP 1',
              'is_sellable': true,
              'currency_code': 'VND',
              'list_price_minor': 10000,
              'units': [
                {
                  'product_unit_id': unitUuid,
                  'unit_code': 'HOP',
                  'unit_name': 'Hộp',
                  'is_default': true,
                  'is_active': true,
                  'is_sellable': true,
                  'list_price_minor': 10000,
                },
              ],
            },
          ],
        };

        final res = await repository.searchSellable(
          storeId: storeId,
          keyword: 'para',
          limit: 20,
          offset: 0,
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'search_sellable_products');
        expect(rpc.calls.first.params, _expectedSearchSellableParams);
        expect(res.length, 1);
        expect(res.first.displayName, 'SP 1');
      });

      test('H1 18: resolve_sellable_barcode params', () async {
        rpc.nextCallResult = {'items': []};

        final res = await repository.resolveSellableBarcode(
          storeId: storeId,
          barcode: '893123456',
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'resolve_sellable_barcode');
        expect(rpc.calls.first.params, _expectedResolveSellableBarcodeParams);
        expect(res, isEmpty);
      });

      test('H1 19: list_sellable_product_units params', () async {
        rpc.nextCallResult = {'units': []};

        final res = await repository.listSellableUnits(
          storeId: storeId,
          productId: productId,
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'list_sellable_product_units');
        expect(rpc.calls.first.params, _expectedListSellableUnitsParams);
        expect(res, isEmpty);
      });

      test('H1 20: resolve_sellable_products params', () async {
        const validUuid = '11111111-1111-4111-8111-111111111111';
        rpc.nextCallResult = {
          'items': [
            {
              'product_id': validUuid,
              'resolution': 'not_found',
            },
          ],
        };

        final res = await repository.resolveSellable(
          storeId: storeId,
          productIds: const ['prod-1', 'prod-2'],
        );

        expect(rpc.calls.length, 1);
        expect(rpc.calls.first.rpc, 'resolve_sellable_products');
        expect(rpc.calls.first.params, _expectedResolveSellableProductsParams);
        expect(res.length, 1);
        expect(res.first.resolution, app_enum.SellableProductResolution.notFound);
      });

      test('H9: slot image edge cases for requestImageUpload', () async {
        // 1. Empty rows -> "Image upload slot was not created."
        rpc.nextRowsResult = [];
        await expectLater(
          repository.requestImageUpload(fileName: 'a.png', contentType: 'image/png', byteSize: 100),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Image upload slot was not created.'),
          ),
        );
        expect(signedKeys, isEmpty);

        // 2. Missing slotId -> "Invalid image upload slot response."
        rpc.nextRowsResult = [{'slot_id': '', 'storage_key': 'k1'}];
        await expectLater(
          repository.requestImageUpload(fileName: 'a.png', contentType: 'image/png', byteSize: 100),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Invalid image upload slot response.'),
          ),
        );
        expect(signedKeys, isEmpty);

        // 3. Missing storageKey -> "Invalid image upload slot response."
        rpc.nextRowsResult = [{'slot_id': 's1', 'storage_key': ''}];
        await expectLater(
          repository.requestImageUpload(fileName: 'a.png', contentType: 'image/png', byteSize: 100),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Invalid image upload slot response.'),
          ),
        );
        expect(signedKeys, isEmpty);

        // 4. StorageException during sign -> rethrows AppException with unknown code & serverMessage
        rpc.nextRowsResult = [{'slot_id': 's1', 'storage_key': 'k1'}];
        final failingRepo = ProductRepository(
          rpc: rpc,
          tenantId: () async => tenantId,
          actorId: () async => actorId,
          hasPermission: (p) => true,
          signUploadUrl: (key) async => throw const StorageException('storage error 500'),
        );
        await expectLater(
          failingRepo.requestImageUpload(fileName: 'a.png', contentType: 'image/png', byteSize: 100),
          throwsA(
            isA<AppException>()
                .having((e) => e.code, 'code', AppErrorCode.unknown)
                .having((e) => e.serverMessage, 'serverMessage', 'storage error 500'),
          ),
        );

        // 5. Null expires_at -> defaults to now + 1 hour ± 1 minute
        rpc.nextRowsResult = [{'slot_id': 's1', 'storage_key': 'k1', 'expires_at': null}];
        final before = DateTime.now().toUtc().add(const Duration(minutes: 59));
        final slotWithDefaultExpiry = await repository.requestImageUpload(
          fileName: 'a.png',
          contentType: 'image/png',
          byteSize: 100,
        );
        final after = DateTime.now().toUtc().add(const Duration(minutes: 61));
        expect(slotWithDefaultExpiry.expiresAt.isAfter(before), isTrue);
        expect(slotWithDefaultExpiry.expiresAt.isBefore(after), isTrue);
      });

      test('H9: slot image edge cases for requestMaintenanceImageUpload', () async {
        // 1. Empty rows -> "Image upload slot was not created."
        rpc.nextRowsResult = [];
        await expectLater(
          repository.requestMaintenanceImageUpload(
            productId: productId,
            fileName: 'a.png',
            contentType: 'image/png',
            byteSize: 100,
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Image upload slot was not created.'),
          ),
        );
        expect(signedKeys, isEmpty);

        // 2. Missing slotId -> "Invalid image upload slot response."
        rpc.nextRowsResult = [{'slot_id': '', 'storage_key': 'k1'}];
        await expectLater(
          repository.requestMaintenanceImageUpload(
            productId: productId,
            fileName: 'a.png',
            contentType: 'image/png',
            byteSize: 100,
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Invalid image upload slot response.'),
          ),
        );
        expect(signedKeys, isEmpty);

        // 3. Missing storageKey -> "Invalid image upload slot response."
        rpc.nextRowsResult = [{'slot_id': 's1', 'storage_key': ''}];
        await expectLater(
          repository.requestMaintenanceImageUpload(
            productId: productId,
            fileName: 'a.png',
            contentType: 'image/png',
            byteSize: 100,
          ),
          throwsA(
            isA<AppException>().having((e) => e.serverMessage, 'serverMessage', 'Invalid image upload slot response.'),
          ),
        );
        expect(signedKeys, isEmpty);

        // 4. StorageException during sign -> rethrows AppException with unknown code & serverMessage
        rpc.nextRowsResult = [{'slot_id': 's1', 'storage_key': 'k1'}];
        final failingRepo = ProductRepository(
          rpc: rpc,
          tenantId: () async => tenantId,
          actorId: () async => actorId,
          hasPermission: (p) => true,
          signUploadUrl: (key) async => throw const StorageException('storage error 500'),
        );
        await expectLater(
          failingRepo.requestMaintenanceImageUpload(
            productId: productId,
            fileName: 'a.png',
            contentType: 'image/png',
            byteSize: 100,
          ),
          throwsA(
            isA<AppException>()
                .having((e) => e.code, 'code', AppErrorCode.unknown)
                .having((e) => e.serverMessage, 'serverMessage', 'storage error 500'),
          ),
        );

        // 5. Null expires_at -> defaults to now + 1 hour ± 1 minute
        rpc.nextRowsResult = [{'slot_id': 's1', 'storage_key': 'k1', 'expires_at': null}];
        final before = DateTime.now().toUtc().add(const Duration(minutes: 59));
        final slotWithDefaultExpiry = await repository.requestMaintenanceImageUpload(
          productId: productId,
          fileName: 'a.png',
          contentType: 'image/png',
          byteSize: 100,
        );
        final after = DateTime.now().toUtc().add(const Duration(minutes: 61));
        expect(slotWithDefaultExpiry.expiresAt.isAfter(before), isTrue);
        expect(slotWithDefaultExpiry.expiresAt.isBefore(after), isTrue);
      });

      test('reclassifies PostgrestException into CatalogErrorCodes via _guard', () async {
        rpc.errorToThrow = const PostgrestException(message: 'duplicate sku "A1"');
        await expectLater(
          repository.checkDuplicateCodes(sku: 'A1'),
          throwsA(
            isA<AppException>()
                .having((e) => e.code, 'code', CatalogErrorCodes.duplicateSku)
                .having((e) => e.details?['value'], 'details.value', 'A1'),
          ),
        );
      });
    });
  });
}

class _RpcCall {
  _RpcCall(this.schema, this.rpc, this.params, this.isCall);
  final String schema;
  final String rpc;
  final Map<String, dynamic>? params;
  final bool isCall;
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <_RpcCall>[];
  Object? nextCallResult;
  List<Map<String, dynamic>> nextRowsResult = [];
  Object? errorToThrow;

  @override
  Future<dynamic> call(String schema, String rpc, {Map<String, dynamic>? params}) async {
    calls.add(_RpcCall(schema, rpc, params, true));
    if (errorToThrow != null) {
      if (errorToThrow is AppException) {
        throw errorToThrow!;
      }
      throw AppException.from(errorToThrow!);
    }
    return nextCallResult;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(String schema, String rpc, {Map<String, dynamic>? params}) async {
    calls.add(_RpcCall(schema, rpc, params, false));
    if (errorToThrow != null) {
      if (errorToThrow is AppException) {
        throw errorToThrow!;
      }
      throw AppException.from(errorToThrow!);
    }
    return nextRowsResult;
  }

  @override
  Future<Map<String, dynamic>> firstRow(String schema, String rpc, {Map<String, dynamic>? params}) async {
    final r = await rows(schema, rpc, params: params);
    if (r.isEmpty) {
      throw const AppException(AppErrorCode.unknown, serverMessage: 'No rows returned');
    }
    return r.first;
  }
}
