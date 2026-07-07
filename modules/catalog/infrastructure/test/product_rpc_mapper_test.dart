import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/product_rpc_mapper.dart';

void main() {
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
      expect(result.previousStatus, ProductStatus.active);
      expect(result.currentStatus, ProductStatus.inactive);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.single.code,
        ReadinessBlockerCode.missingPriceBand,
      );
      expect(result.version, 2);
      expect(result.reason, 'Ngừng theo mùa');
      expect(result.warnings.single.code, ProductBusinessStatusWarningCode.hasStock);
      expect(result.historyEntry?.valueBefore, ProductStatus.active.name);
      expect(result.historyEntry?.valueAfter, ProductStatus.inactive.name);
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
        'business_status': 'active',
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
          'value_before': 'false',
          'value_after': 'true',
        },
      });

      expect(result.productId, 'product-6');
      expect(result.isSoftDeleted, isTrue);
      expect(result.businessStatus, ProductStatus.active);
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
      expect(result.version, 2);
      expect(result.reason, 'Dọn danh mục');
      expect(result.issues.single.code, ProductDeletionIssueCode.hasHistoricalTransactions);
      expect(result.historyEntry?.valueBefore, 'false');
      expect(result.historyEntry?.valueAfter, 'true');
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
      expect(result.businessStatus, ProductStatus.inactive);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.single.code,
        ReadinessBlockerCode.missingPriceBand,
      );
      expect(result.version, 3);
    });
  });

  group('ProductRpcMapper (US-02 Operational Data)', () {
    test('setInitialStockParams maps stock profile to RPC parameters', () {
      final profile = ProductStockProfile.basic(initialStock: 150.0);
      final params = ProductRpcMapper.setInitialStockParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        profile: profile,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'prod-1');
      expect(params['p_mode'], 'basic');
      expect(params['p_initial_stock'], 150.0);
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
      expect(params['p_base_price'], 85000.0);
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
        listPrice: ListPrice(amount: 120000.0),
        floorPrice: FloorPrice(amount: 100000.0),
      );
      final params = ProductRpcMapper.setInitialPriceBandParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        priceBand: band,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'prod-1');
      expect(params['p_product_unit_id'], 'unit-box');
      expect(params['p_list_price'], 120000.0);
      expect(params['p_floor_price'], 100000.0);
    });

    test('setInitialPriceBandParams omits unit id when base unit not specified', () {
      final band = ProductUnitPriceBand(
        id: 'band-1',
        tenantId: 'tenant-1',
        productId: 'prod-1',
        listPrice: ListPrice(amount: 120000.0),
        floorPrice: FloorPrice(amount: 100000.0),
      );
      final params = ProductRpcMapper.setInitialPriceBandParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        priceBand: band,
      );

      expect(params.containsKey('p_product_unit_id'), isFalse);
      expect(params['p_list_price'], 120000.0);
      expect(params['p_floor_price'], 100000.0);
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
          newQuantity: 25.0,
          reason: 'Kiểm kê',
          expectedQuantity: 150.0,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_new_quantity'], 25.0);
      expect(params['p_reason'], 'Kiểm kê');
      expect(params['p_expected_quantity'], 150.0);
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
}
