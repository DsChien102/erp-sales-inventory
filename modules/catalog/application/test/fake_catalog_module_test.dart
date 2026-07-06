import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('FakeCatalogModule', () {
    test('guided_create_ok returns product and readiness blockers', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateOk,
      );

      final result = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Amoxicillin 100ml',
          baseUnitName: 'Lọ',
        ),
      );

      expect(result.productId, startsWith('product-new-'));
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingPrice),
      );
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
    });

    test('guided_create_dup_sku throws DuplicateSkuException', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateDupSku,
      );

      await expectLater(
        module.executeCommandAsync(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: 'Thuốc A',
            sku: 'SKU-001',
          ),
        ),
        throwsA(
          isA<DuplicateSkuException>().having((e) => e.sku, 'sku', 'SKU-001'),
        ),
      );
    });

    test('guided_create_dup_barcode throws DuplicateBarcodeException', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateDupBarcode,
      );

      await expectLater(
        module.executeCommandAsync(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: 'Thuốc A',
            barcode: '8901234567890',
          ),
        ),
        throwsA(
          isA<DuplicateBarcodeException>().having(
            (e) => e.barcode,
            'barcode',
            '8901234567890',
          ),
        ),
      );
    });

    test('guided_create_missing_name throws ValidationException', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateMissingName,
      );

      await expectLater(
        module.executeCommandAsync(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: '',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('guided_create_no_images returns optional image blocker', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateNoImages,
      );

      final result = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc B',
          baseUnitName: 'Hộp',
        ),
      );

      expect(result.productId, startsWith('product-new-'));
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingImage),
      );
    });

    test('guided_create_upload_slot_ok returns upload slot', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateUploadSlotOk,
      );

      final result = await module.executeCommandAsync(
        RequestProductImageUploadCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          fileName: 'photo.jpg',
          contentType: 'image/jpeg',
          byteSize: 2048,
        ),
      );

      expect(result.slotId, startsWith('slot-'));
      expect(result.storageKey, contains('staging'));
      expect(result.signedUploadUrl, isNotEmpty);
    });

    test('guided_create_upload_invalid_type throws ValidationException', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateUploadInvalidType,
      );

      await expectLater(
        module.executeCommandAsync(
          RequestProductImageUploadCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            fileName: 'photo.gif',
            contentType: 'image/gif',
            byteSize: 1024,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'guided_create_permission_denied throws ApplicationException',
      () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.guidedCreatePermissionDenied,
        );

        await expectLater(
          module.executeCommandAsync(
            CreateProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productName: 'Thuốc C',
            ),
          ),
          throwsA(
            isA<ApplicationException>().having(
              (e) => e.message,
              'message',
              'Permission denied',
            ),
          ),
        );
      },
    );

    test('dup sku scenario returns matches from check query', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateDupSku,
      );

      final matches = await module.executeQueryAsync(
        CheckDuplicateProductCodeQuery(
          tenantId: 'tenant-1',
          sku: 'SKU-001',
        ),
      );

      expect(matches, hasLength(1));
      expect(matches.single.field, ProductDuplicateField.sku);
      expect(matches.single.matchedValue, 'SKU-001');
    });

    test('ok scenario returns empty duplicate matches', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.guidedCreateOk,
      );

      final matches = await module.executeQueryAsync(
        CheckDuplicateProductCodeQuery(
          tenantId: 'tenant-1',
          sku: 'SKU-NEW',
        ),
      );

      expect(matches, isEmpty);
    });

    test('initial_stock_ok sets stock quantity without error', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.initialStockOk,
      );

      await module.executeCommandAsync(
        SetInitialStockCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          quantity: 200,
        ),
      );
    });

    test('manual_base_price_ok sets base cost without error', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.manualBasePriceOk,
      );

      await module.executeCommandAsync(
        SetManualBasePriceCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          basePrice: 90000.0,
        ),
      );
    });

    test('price_band_from_store_rule sets price band without error', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.priceBandFromStoreRule,
      );

      await module.executeCommandAsync(
        SetInitialPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          listPrice: 150000.0,
          floorPrice: 110000.0,
          useStoreRule: true,
        ),
      );
    });

    test('scn_e02_u03_fr01_01 readiness_many_blockers checklist', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessManyBlockers,
      );

      final createResult = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc A',
        ),
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: createResult.productId,
        ),
      );

      expect(view.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        view.checklist.map((item) => item.status),
        contains(ReadinessChecklistItemStatus.missing),
      );
      expect(
        view.readinessSummary.blockers.map((b) => b.code),
        containsAll([
          ReadinessBlockerCode.missingBaseUnit,
          ReadinessBlockerCode.missingStock,
          ReadinessBlockerCode.missingPrice,
          ReadinessBlockerCode.missingPriceBand,
        ]),
      );
    });

    test('scn_e02_u03_fr01_02 readiness_ready_to_sell', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessReadyToSell,
      );

      final createResult = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc B',
          baseUnitName: 'Lọ',
          images: const [
            ProductImageInput(
              storageKey: 'tenant-1/staging/slot-1/original.jpeg',
              isPrimary: true,
              sortOrder: 0,
            ),
          ],
        ),
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: createResult.productId,
        ),
      );

      expect(view.readinessSummary.status, ReadinessStatus.readyToSell);
      expect(view.primaryActionId, ContextualActionId.createAnotherProduct);
      expect(view.readinessSummary.blockers, isEmpty);
    });

    test('scn_e02_u03_fr01_03 readiness_advanced_stock_pending', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessAdvancedStockPending,
      );

      final createResult = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc C',
          baseUnitName: 'Lọ',
        ),
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: createResult.productId,
        ),
      );

      final stockItem = view.checklist.singleWhere(
        (item) => item.group == ReadinessChecklistGroup.stock,
      );
      expect(stockItem.status, ReadinessChecklistItemStatus.pendingExternal);
      expect(
        view.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.pendingStockFromInventory),
      );
      expect(
        view.suggestedActions.map((a) => a.actionId),
        isNot(contains(ContextualActionId.setInitialStock)),
      );
    });

    test('scn_e02_u03_fr01_04 readiness_costing_base_price_pending', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessCostingBasePricePending,
      );

      final createResult = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc D',
          baseUnitName: 'Lọ',
        ),
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: createResult.productId,
        ),
      );

      final basePriceItem = view.checklist.singleWhere(
        (item) => item.group == ReadinessChecklistGroup.basePrice,
      );
      expect(basePriceItem.status, ReadinessChecklistItemStatus.pendingExternal);
      expect(
        view.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.pendingBasePriceFromCosting),
      );
    });

    test('scn_e02_u03_fr01_05 readiness_missing_custom_fields', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessMissingCustomFields,
      );

      final createResult = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc E',
          baseUnitName: 'Lọ',
        ),
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: createResult.productId,
        ),
      );

      expect(
        view.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingRequiredCustomFields),
      );
    });

    test('scn_e02_u03_fr03_01 suggests set_base_unit when missing unit', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessManyBlockers,
      );

      final createResult = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc F',
        ),
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: createResult.productId,
        ),
      );

      expect(view.primaryActionId, ContextualActionId.setBaseUnit);
      expect(
        view.suggestedActions.singleWhere(
          (a) => a.actionId == ContextualActionId.setBaseUnit,
        ).label,
        'Thiết lập đơn vị cơ sở',
      );
    });

    test('scn_e02_u03_fr03_03 readiness_no_price_permission', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessNoPricePermission,
      );

      final createResult = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc G',
          baseUnitName: 'Lọ',
        ),
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: createResult.productId,
        ),
      );

      expect(
        view.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingPriceBand),
      );
      final priceAction = view.suggestedActions.singleWhere(
        (a) => a.actionId == ContextualActionId.setPriceBand,
      );
      expect(priceAction.enabled, isFalse);
    });

    test('scn_e02_u03_fr04_01 readiness_refresh_after_unit', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessRefreshAfterUnit,
      );

      final createResult = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc H',
          baseUnitName: 'Lọ',
        ),
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: createResult.productId,
        ),
      );

      final unitItem = view.checklist.singleWhere(
        (item) => item.group == ReadinessChecklistGroup.units,
      );
      expect(unitItem.status, ReadinessChecklistItemStatus.complete);
      expect(
        view.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
      expect(
        view.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingPriceBand),
      );
    });

    test('scn_e02_u03_fr02_04 readiness_permission_denied', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessPermissionDenied,
      );

      await expectLater(
        module.executeQueryAsync(
          GetProductReadinessQuery(
            tenantId: 'tenant-1',
            productId: 'product-new-1',
          ),
        ),
        throwsA(isA<ApplicationException>()),
      );
    });
  });

  group('CreateProductCommandValidator', () {
    final validator = CreateProductCommandValidator();

    test('rejects empty product name', () async {
      await expectLater(
        validator.validate(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: '   ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts minimal valid command', () async {
      await validator.validate(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Amoxicillin 100ml',
        ),
      );
    });
  });
}
