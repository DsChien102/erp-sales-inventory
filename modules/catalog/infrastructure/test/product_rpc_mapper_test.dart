import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/product_rpc_mapper.dart';

void main() {
  group('ProductRpcMapper atomic guided create', () {
    test('maps the complete wizard to one RPC payload', () {
      final params = ProductRpcMapper.createGuidedProductParams(
        CreateGuidedProductCommand(
          id: '550e8400-e29b-41d4-a716-446655440000',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          productName: 'Thuốc A',
          note: 'Hàng nhập từ nhà cung cấp A',
          baseUnit: const ExistingTenantUnit('unit-hop'),
          basicStockQuantityBase: 12,
          basePrice: 10000,
          listBeforeVat: 13000,
          floorBeforeVat: 11000,
          priceBandSourceType: PriceBandSourceType.customConfig,
          listMarkupRatio: 0.3,
          floorMarkupRatio: 0.1,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_note'], 'Hàng nhập từ nhà cung cấp A');
      expect(params['p_tenant_unit_id'], 'unit-hop');
      expect(params['p_basic_stock_quantity_base'], 12);
      expect(params['p_base_price_after_vat'], 10000);
      expect(params['p_list_price_before_vat'], 13000);
      expect(params['p_price_band_source_type'], 'customConfig');
      expect(params['p_list_markup_ratio'], 0.3);
      expect(params['p_floor_markup_ratio'], 0.1);
      expect(params['p_idempotency_key'], '550e8400-e29b-41d4-a716-446655440000');
      expect(params['p_reference_id'], startsWith('P'));
    });

    test('maps RPC result readiness', () {
      final result = ProductRpcMapper.createGuidedProductResultFromJson({
        'product_id': 'product-1',
        'readiness_status': 'ready_to_receive',
        'readiness_blockers': const <dynamic>[],
      });

      expect(result.productId, 'product-1');
      expect(result.readinessSummary.status, ReadinessStatus.readyToReceive);
    });
  });

  group('ProductRpcMapper (EPIC-07/US-01 profile maintenance)', () {
    test('updateProductProfileParams maps command to RPC parameters', () {
      final params = ProductRpcMapper.updateProductProfileParams(
        UpdateProductProfileCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-1',
          productName: '  Thuốc A mới  ',
          commercialName: 'Trade A',
          sku: 'SKU-NEW',
          barcode: '8930000000099',
          description: 'Desc',
          note: 'Note',
          expectedVersion: 1,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_actor_id'], 'user-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_name'], 'Thuốc A mới');
      expect(params['p_trade_name'], 'Trade A');
      expect(params['p_sku'], 'SKU-NEW');
      expect(params['p_barcode'], '8930000000099');
      expect(params['p_description'], 'Desc');
      expect(params['p_note'], 'Note');
      expect(params['p_expected_version'], 1);
    });

    test('updateProductImagesParams maps image snapshot to RPC parameters', () {
      final params = ProductRpcMapper.updateProductImagesParams(
        UpdateProductImagesCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-1',
          images: const [
            ProductImageMutationInput(
              imageId: 'image-2',
              storageKey: 'tenant-1/products/product-1/image-2.webp',
              slotId: 'slot-2',
              url: 'https://cdn.fake/image-2.webp',
              isPrimary: true,
              sortOrder: 0,
            ),
          ],
          expectedVersion: 3,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_actor_id'], 'user-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_expected_version'], 3);
      expect(params['p_images'], [
        {
          'image_id': 'image-2',
          'storage_key': 'tenant-1/products/product-1/image-2.webp',
          'slot_id': 'slot-2',
          'url': 'https://cdn.fake/image-2.webp',
          'is_primary': true,
          'sort_order': 0,
        },
      ]);
    });

    test('updateProductProfileResultFromRow maps refreshed profile and readiness', () {
      final result = ProductRpcMapper.updateProductProfileResultFromRow({
        'product_id': 'product-1',
        'name': 'Thuốc A mới',
        'trade_name': 'Trade A',
        'sku': 'SKU-NEW',
        'barcode': '8930000000099',
        'description': 'Desc',
        'note': 'Note',
        'business_status': 'active',
        'is_soft_deleted': false,
        'primary_image_url': 'https://cdn.fake/image.webp',
        'images': ['https://cdn.fake/image.webp'],
        'readiness_status': 'ready_to_sell',
        'readiness_blockers': [],
        'version': 2,
      });

      expect(result.productId, 'product-1');
      expect(result.profile.name, 'Thuốc A mới');
      expect(result.profile.primaryImageUrl, 'https://cdn.fake/image.webp');
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
      expect(result.version, 2);
    });

    test('updateProductImagesResultFromRow maps visible gallery result', () {
      final result = ProductRpcMapper.updateProductImagesResultFromRow({
        'product_id': 'product-1',
        'images': [
          {
            'image_id': 'image-1',
            'storage_key': 'tenant-1/products/product-1/image-1.webp',
            'url': 'https://cdn.fake/image-1.webp',
            'is_primary': true,
            'sort_order': 0,
          },
        ],
        'primary_image_url': 'https://cdn.fake/image-1.webp',
        'readiness_status': 'incomplete',
        'readiness_blockers': [
          {
            'code': ReadinessBlockerCode.missingPrice,
            'message': 'Thiếu giá cơ sở',
            'group': 'basePrice',
          },
        ],
        'version': 2,
      });

      expect(result.productId, 'product-1');
      expect(result.images.single.imageId, 'image-1');
      expect(result.images.single.isPrimary, isTrue);
      expect(result.primaryImageUrl, 'https://cdn.fake/image-1.webp');
      expect(
        result.readinessSummary.blockers.single.code,
        ReadinessBlockerCode.missingPrice,
      );
    });
  });

  group('ProductRpcMapper (EPIC-07/US-02 product business status)', () {
    test('deactivateProductParams maps command to RPC parameters', () {
      final params = ProductRpcMapper.deactivateProductParams(
        DeactivateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-4',
          reason: 'Ngừng theo mùa',
          expectedVersion: 1,
          confirmAcknowledgeWarnings: true,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_actor_id'], 'user-1');
      expect(params['p_product_id'], 'product-4');
      expect(params['p_reason'], 'Ngừng theo mùa');
      expect(params['p_expected_version'], 1);
      expect(params['p_confirm_acknowledge_warnings'], isTrue);
    });

    test('reactivateProductParams maps command to RPC parameters', () {
      final params = ProductRpcMapper.reactivateProductParams(
        ReactivateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-5',
          reason: 'Kinh doanh lại',
          expectedVersion: 2,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_actor_id'], 'user-1');
      expect(params['p_product_id'], 'product-5');
      expect(params['p_reason'], 'Kinh doanh lại');
      expect(params['p_expected_version'], 2);
    });

    test('changeProductBusinessStatusResultFromRow maps result row', () {
      final result = ProductRpcMapper.changeProductBusinessStatusResultFromRow({
        'product_id': 'product-4',
        'previous_status': 'active',
        'current_status': 'inactive',
        'readiness_status': 'incomplete',
        'readiness_blockers': [
          {
            'code': ReadinessBlockerCode.missingPriceBand,
            'message': 'Thiếu khung giá bán',
            'group': 'priceBand',
          },
        ],
        'version': 2,
        'reason': 'Ngừng theo mùa',
        'warnings': [
          {
            'code': ProductBusinessStatusWarningCode.hasStock,
            'message': 'Sản phẩm vẫn còn tồn kho hiện hành.',
          },
        ],
        'history_entry': {
          'id': 'history-1',
          'occurred_at': '2026-07-07T09:00:00.000Z',
          'actor_display_name': 'user-1',
          'change_type': 'product_status_changed',
          'summary': 'Ngừng kinh doanh sản phẩm',
          'value_before': 'active',
          'value_after': 'inactive',
        },
      });

      expect(result.productId, 'product-4');
      expect(result.previousStatus, ProductBusinessStatus.active);
      expect(result.currentStatus, ProductBusinessStatus.inactive);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.single.code,
        ReadinessBlockerCode.missingPriceBand,
      );
      expect(result.version, 2);
      expect(result.reason, 'Ngừng theo mùa');
      expect(result.warnings.single.code, ProductBusinessStatusWarningCode.hasStock);
      expect(result.historyEntry?.valueBefore, ProductBusinessStatus.active.name);
      expect(result.historyEntry?.valueAfter, ProductBusinessStatus.inactive.name);
    });
  });

  group('ProductRpcMapper (EPIC-07/US-03 product soft delete)', () {
    test('checkProductDeletionEligibilityParams maps query to RPC parameters', () {
      final params = ProductRpcMapper.checkProductDeletionEligibilityParams(
        CheckProductDeletionEligibilityQuery(
          tenantId: 'tenant-1',
          productId: 'product-6',
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-6');
    });

    test('deleteProductParams maps command to RPC parameters', () {
      final params = ProductRpcMapper.deleteProductParams(
        DeleteProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-6',
          reason: 'Dọn danh mục',
          expectedVersion: 1,
          confirmAcknowledgeWarnings: true,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_actor_id'], 'user-1');
      expect(params['p_product_id'], 'product-6');
      expect(params['p_reason'], 'Dọn danh mục');
      expect(params['p_expected_version'], 1);
      expect(params['p_confirm_acknowledge_warnings'], isTrue);
    });

    test('restoreProductParams maps command to RPC parameters', () {
      final params = ProductRpcMapper.restoreProductParams(
        RestoreProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-7',
          reason: 'Khôi phục nhầm xóa',
          expectedVersion: 2,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_actor_id'], 'user-1');
      expect(params['p_product_id'], 'product-7');
      expect(params['p_reason'], 'Khôi phục nhầm xóa');
      expect(params['p_expected_version'], 2);
    });

    test('productDeletionEligibilityFromRow maps issue severities', () {
      final result = ProductRpcMapper.productDeletionEligibilityFromRow({
        'product_id': 'product-4',
        'can_delete': false,
        'suggested_action_id': 'deactivate_product',
        'issues': [
          {
            'code': ProductDeletionIssueCode.openTransaction,
            'message': 'Sản phẩm đang được dùng trong giao dịch mở.',
            'severity': 'blocker',
          },
          {
            'code': ProductDeletionIssueCode.hasHistoricalTransactions,
            'message': 'Sản phẩm có giao dịch lịch sử.',
            'severity': 'warning',
          },
          {
            'code': ProductDeletionIssueCode.hasStock,
            'message': 'Sản phẩm vẫn còn tồn kho.',
            'severity': 'recommendation',
          },
          {
            'code': ProductDeletionIssueCode.activePromotion,
            'message': 'Sản phẩm đang nằm trong chương trình khuyến mãi.',
            'severity': 'warning',
          },
        ],
      });

      expect(result.productId, 'product-4');
      expect(result.canDelete, isFalse);
      expect(result.suggestedActionId, 'deactivate_product');
      expect(result.issues, hasLength(4));
      expect(result.blockers.single.code, ProductDeletionIssueCode.openTransaction);
      expect(
        result.warnings.map((issue) => issue.code),
        containsAll([
          ProductDeletionIssueCode.hasHistoricalTransactions,
          ProductDeletionIssueCode.activePromotion,
        ]),
      );
      expect(
        result.issues
            .singleWhere((issue) => issue.code == ProductDeletionIssueCode.hasStock)
            .severity,
        ProductDeletionIssueSeverity.recommendation,
      );
    });

    test('changeProductSoftDeleteResultFromRow maps delete result row', () {
      final result = ProductRpcMapper.changeProductSoftDeleteResultFromRow({
        'product_id': 'product-6',
        'is_soft_deleted': true,
        'business_status': 'soft_deleted',
        'readiness_status': 'ready_to_sell',
        'readiness_blockers': [],
        'version': 2,
        'reason': 'Dọn danh mục',
        'issues': [
          {
            'code': ProductDeletionIssueCode.hasHistoricalTransactions,
            'message': 'Sản phẩm có giao dịch lịch sử.',
            'severity': 'warning',
          },
        ],
        'history_entry': {
          'id': 'history-delete-1',
          'occurred_at': '2026-07-07T11:00:00.000Z',
          'actor_display_name': 'user-1',
          'change_type': 'product_soft_deleted',
          'summary': 'Xóa mềm sản phẩm',
          'value_before': 'active',
          'value_after': 'soft_deleted',
        },
      });

      expect(result.productId, 'product-6');
      expect(result.isSoftDeleted, isTrue);
      expect(result.businessStatus, ProductBusinessStatus.softDeleted);
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
      expect(result.version, 2);
      expect(result.reason, 'Dọn danh mục');
      expect(result.issues.single.code, ProductDeletionIssueCode.hasHistoricalTransactions);
      expect(result.historyEntry?.valueBefore, 'active');
      expect(result.historyEntry?.valueAfter, 'soft_deleted');
    });

    test('changeProductSoftDeleteResultFromRow maps restore result row', () {
      final result = ProductRpcMapper.changeProductSoftDeleteResultFromRow({
        'product_id': 'product-7',
        'is_soft_deleted': false,
        'business_status': 'inactive',
        'readiness_status': 'incomplete',
        'readiness_blockers': [
          {
            'code': ReadinessBlockerCode.missingPriceBand,
            'message': 'Thiếu khung giá bán',
            'group': 'priceBand',
          },
        ],
        'version': 3,
        'reason': 'Khôi phục nhầm xóa',
      });

      expect(result.productId, 'product-7');
      expect(result.isSoftDeleted, isFalse);
      expect(result.businessStatus, ProductBusinessStatus.inactive);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.single.code,
        ReadinessBlockerCode.missingPriceBand,
      );
      expect(result.version, 3);
    });
  });

  group('ProductRpcMapper (US-02 Operational Data)', () {
    test('setBasicStockQuantityBaseParams maps stock profile to RPC parameters', () {
      final profile = ProductStockProfile.basic(basicStockQuantityBase: 150);
      final params = ProductRpcMapper.setBasicStockQuantityBaseParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        profile: profile,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'prod-1');
      expect(params['p_mode'], 'basic');
      expect(params['p_basic_stock_quantity_base'], 150);
    });

    test('setManualBasePriceParams maps base price profile to RPC parameters', () {
      final profile = ProductBasePriceProfile.manual(
        basePrice: BasePrice(amount: 85000.0),
      );
      final params = ProductRpcMapper.setManualBasePriceParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        profile: profile,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'prod-1');
      expect(params['p_mode'], 'manual');
      expect(params['p_base_price_after_vat'], 85000.0);
      expect(params['p_currency'], 'VND');
    });

    test('setManualBasePriceParams forwards custom currency', () {
      final profile = ProductBasePriceProfile.manual(
        basePrice: BasePrice(amount: 1000.0),
      );
      final params = ProductRpcMapper.setManualBasePriceParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        profile: profile,
        currency: 'USD',
      );

      expect(params['p_currency'], 'USD');
    });

    test('setInitialPriceBandParams maps price band to RPC parameters', () {
      final band = ProductUnitPriceBand(
        id: 'band-1',
        tenantId: 'tenant-1',
        productId: 'prod-1',
        productUnitId: 'unit-box',
        listBeforeVat: Money(120000),
        floorBeforeVat: Money(100000),
        effectiveFrom: DateTime.utc(2026, 1, 1),
      );
      final params = ProductRpcMapper.setInitialPriceBandParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        priceBand: band,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'prod-1');
      expect(params['p_product_unit_id'], 'unit-box');
      expect(params['p_list_price_before_vat'], 120000);
      expect(params['p_floor_price_before_vat'], 100000);
      expect(params['p_effective_from'], '2026-01-01T00:00:00.000Z');
      expect(params['p_status'], 'active');
    });

    test('setInitialPriceBandParams omits unit id when base unit not specified', () {
      final band = ProductUnitPriceBand(
        id: 'band-1',
        tenantId: 'tenant-1',
        productId: 'prod-1',
        listBeforeVat: Money(120000),
        floorBeforeVat: Money(100000),
        effectiveFrom: DateTime.utc(2026, 1, 1),
      );
      final params = ProductRpcMapper.setInitialPriceBandParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        priceBand: band,
      );

      expect(params.containsKey('p_product_unit_id'), isFalse);
      expect(params['p_list_price_before_vat'], 120000);
      expect(params['p_floor_price_before_vat'], 100000);
    });
  });

  group('ProductRpcMapper (EPIC-04/US-01 units)', () {
    test('listTenantUnitsParams maps picker params', () {
      final params = ProductRpcMapper.listTenantUnitsParams(
        tenantId: 'tenant-1',
        keyword: 'lo',
        limit: 20,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_keyword'], 'lo');
      expect(params['p_limit'], 20);
    });

    test('checkDuplicateUnitNameParams maps duplicate-check params', () {
      final params = ProductRpcMapper.checkDuplicateUnitNameParams(
        tenantId: 'tenant-1',
        name: 'Lọ',
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_name'], 'Lọ');
    });

    test('setProductBaseUnitParams maps existing unit selection', () {
      final params = ProductRpcMapper.setProductBaseUnitParams(
        SetProductBaseUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-6',
          selection: const ExistingTenantUnit('unit-lo'),
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-6');
      expect(params['p_tenant_unit_id'], 'unit-lo');
      expect(params['p_new_unit_name'], isNull);
    });

    test('setProductBaseUnitParams maps new unit selection', () {
      final params = ProductRpcMapper.setProductBaseUnitParams(
        SetProductBaseUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-6',
          selection: const NewTenantUnit('Vỉ'),
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-6');
      expect(params['p_tenant_unit_id'], isNull);
      expect(params['p_new_unit_name'], 'Vỉ');
    });
  });

  group('ProductRpcMapper (EPIC-04/US-02 conversion units)', () {
    test('listProductUnitsParams maps query params', () {
      final params = ProductRpcMapper.listProductUnitsParams(
        ListProductUnitsQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          includeInactive: true,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_include_inactive'], isTrue);
    });

    test('addConversionUnitParams maps command params', () {
      final params = ProductRpcMapper.addConversionUnitParams(
        AddProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          unitName: 'Thùng',
          conversionRateToBase: 100,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_unit_name'], 'Thùng');
      expect(params['p_conversion_rate_to_base'], 100);
    });

    test('deactivateConversionUnitParams maps command params', () {
      final params = ProductRpcMapper.deactivateConversionUnitParams(
        DeactivateProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          productUnitId: 'product-1-unit-vi',
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_product_unit_id'], 'product-1-unit-vi');
    });

    test('reactivateConversionUnitParams maps command params', () {
      final params = ProductRpcMapper.reactivateConversionUnitParams(
        ReactivateProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          productUnitId: 'product-1-unit-thung',
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_product_unit_id'], 'product-1-unit-thung');
    });

    test('deleteConversionUnitParams maps command params', () {
      final params = ProductRpcMapper.deleteConversionUnitParams(
        DeleteProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          productUnitId: 'product-1-unit-vi',
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_product_unit_id'], 'product-1-unit-vi');
    });

    test('productUnitDtoFromRow maps RPC row fields', () {
      final dto = ProductRpcMapper.productUnitDtoFromRow({
        'id': 'product-1-unit-vi',
        'name': 'Vỉ',
        'conversion_rate_to_base': 10,
        'is_base_unit': false,
        'is_active': true,
      });

      expect(dto.id, 'product-1-unit-vi');
      expect(dto.name, 'Vỉ');
      expect(dto.conversionRateToBase, 10);
      expect(dto.isBaseUnit, isFalse);
      expect(dto.isActive, isTrue);
    });

    test('productUnitMutationResultFromRow maps mutation result row', () {
      final result = ProductRpcMapper.productUnitMutationResultFromRow({
        'product_id': 'product-1',
        'unit': {
          'id': 'product-1-unit-thung',
          'name': 'Thùng',
          'conversion_rate_to_base': 100,
          'is_base_unit': false,
          'is_active': true,
        },
      });

      expect(result.productId, 'product-1');
      expect(result.unit.name, 'Thùng');
      expect(result.unit.isActive, isTrue);
    });
  });

  group('ProductRpcMapper (EPIC-05 basic stock)', () {
    test('adjustBasicStockParams maps command to RPC parameters', () {
      final params = ProductRpcMapper.adjustBasicStockParams(
        AdjustBasicStockCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          newQuantity: 25,
          reason: 'Kiểm kê',
          expectedQuantity: 150,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_new_quantity'], 25);
      expect(params['p_reason'], 'Kiểm kê');
      expect(params['p_expected_quantity'], 150);
    });

    test('getProductStockHistoryParams maps query inputs', () {
      final params = ProductRpcMapper.getProductStockHistoryParams(
        tenantId: 'tenant-1',
        productId: 'product-1',
        limit: 20,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_limit'], 20);
    });
  });

  group('ProductRpcMapper (EPIC-03/US-03 custom field search)', () {
    test('searchProductsParams maps custom field filters', () {
      final params = ProductRpcMapper.searchProductsParams(
        tenantId: 'tenant-1',
        criteria: ProductSearchCriteria(
          keyword: 'tiêu hóa',
          customFieldFilters: [
            CustomFieldFilterCriteria(
              fieldId: 'field-1',
              optionId: 'opt-1',
            ),
            CustomFieldFilterCriteria(
              fieldId: 'field-2',
              booleanValue: true,
            ),
          ],
        ),
        limit: 20,
        offset: 0,
      );

      expect(params['p_keyword'], 'tiêu hóa');
      expect(params['p_sort_order'], 'updated_at_desc');
      expect(params['p_custom_field_filters'], [
        {
          'field_id': 'field-1',
          'option_id': 'opt-1',
        },
        {
          'field_id': 'field-2',
          'boolean_value': true,
        },
      ]);
    });

    test('searchProductsParams maps relevance sort order', () {
      final params = ProductRpcMapper.searchProductsParams(
        tenantId: 'tenant-1',
        criteria: ProductSearchCriteria(
          keyword: 'amox',
          sortOrder: ProductSortOrder.relevanceDesc,
        ),
        limit: 20,
        offset: 0,
      );

      expect(params['p_sort_order'], 'relevance_desc');
    });
  });
}
