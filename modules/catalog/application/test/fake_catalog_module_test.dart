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
          quantity: 200.0,
        ),
      );
    });

    test('manual_base_price_ok sets base cost without error', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.manualBasePriceOk,
      );

      final result = await module.executeCommandAsync(
        SetManualBasePriceCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          basePrice: 90000.0,
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.basePrice, 90000.0);
      expect(result.unitName, 'Hộp');
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
        view.suggestedActions
            .singleWhere(
              (a) => a.actionId == ContextualActionId.setBaseUnit,
            )
            .label,
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

  group('EPIC-01 / US-01 search contract', () {
    test('scn_contract_e01_u01_search_empty', () async {
      final module = FakeCatalogModule(scenario: FakeCatalogScenario.searchEmpty);

      final result = await module.executeQueryAsync(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(),
        ),
      );

      expect(result.items, isEmpty);
      expect(result.totalCount, 0);
    });

    test('scn_contract_e01_u01_search_with_readiness', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.searchWithReadiness,
      );

      final result = await module.executeQueryAsync(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(),
        ),
      );

      expect(result.items.length, greaterThanOrEqualTo(3));
      expect(
        result.items.map((item) => item.readinessSummary.status).toSet(),
        contains(ReadinessStatus.incomplete),
      );
      expect(
        result.items.map((item) => item.readinessSummary.status).toSet(),
        contains(ReadinessStatus.readyToSell),
      );
    });

    test('scn_contract_e01_u01_search_filters_incomplete_readiness', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.searchWithReadiness,
      );

      final result = await module.executeQueryAsync(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(
            readinessFilter: ProductReadinessFilter.incomplete,
          ),
        ),
      );

      expect(result.items, isNotEmpty);
      for (final item in result.items) {
        expect(item.readinessSummary.status, ReadinessStatus.incomplete);
      }
    });

    test('scn_contract_e01_u01_barcode_match', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.barcodeExactMatch,
      );

      final result = await module.executeQueryAsync(
        ScanBarcodeQuery(
          tenantId: 'tenant-1',
          barcode: '8930000000001',
        ),
      );

      expect(result, isNotNull);
      expect(result!.id, 'product-1');
      expect(result.barcode, '8930000000001');
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
    });

    test('scn_contract_e01_u01_barcode_not_found', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.barcodeNotFound,
      );

      final result = await module.executeQueryAsync(
        ScanBarcodeQuery(
          tenantId: 'tenant-1',
          barcode: '9999999999999',
        ),
      );

      expect(result, isNull);
    });
  });

  group('EPIC-01 / US-02 control center contract', () {
    test('scn_contract_e01_u02_pcc_incomplete', () async {
      final module = FakeCatalogModule(scenario: FakeCatalogScenario.pccIncomplete);

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-4',
        ),
      );

      expect(result.profile.name, 'Vitamin B Complex');
      expect(result.priceBand.isMissing, isTrue);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(result.checklist, isEmpty);
      expect(
        result.contextualActions.map((a) => a.actionId),
        contains(ContextualActionId.setPriceBand),
      );
    });

    test('scn_contract_e01_u02_pcc_ready', () async {
      final module = FakeCatalogModule(scenario: FakeCatalogScenario.pccReadyToSell);

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.profile.name, 'Amoxicillin 500mg');
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
      expect(result.units.baseUnitName, 'Hộp');
      expect(result.stock.quantity, 150);
      expect(result.checklist, isEmpty);
    });

    test('scn_contract_e01_u02_pcc_inactive', () async {
      final module = FakeCatalogModule(scenario: FakeCatalogScenario.pccInactive);

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-5',
        ),
      );

      expect(result.profile.businessStatus, ProductStatus.inactive);
      expect(result.profile.name, 'Ibuprofen 400mg');
    });

    test('scn_contract_e01_u02_pcc_custom_field_cards', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.pccCustomFieldCards,
      );

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.customFieldGroupCards, hasLength(1));
      expect(result.customFieldGroupCards.first.name, 'Thông tin thuốc');
      expect(result.customFieldGroupCards.first.fields, isNotEmpty);
    });

    test('scn_contract_e01_u02_pcc_change_history_preview', () async {
      final module = FakeCatalogModule(scenario: FakeCatalogScenario.pccReadyToSell);

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.changeHistoryPreview, isNotEmpty);
      expect(result.changeHistoryPreview.first.changeType, 'product_created');
    });
  });

  group('EPIC-04 / US-01 base unit contract', () {
    test('scn_contract_e04_u01_fr01_01 lists tenant measurement units', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.listTenantUnits,
      );

      final units = await module.executeQueryAsync(
        ListTenantMeasurementUnitsQuery(tenantId: 'tenant-1'),
      );

      expect(units.map((unit) => unit.name), containsAll(['Lọ', 'Hộp', 'Vỉ']));
    });

    test('scn_contract_e04_u01_fr01_02 sets existing tenant unit on product', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.setBaseUnitExisting,
      );

      final result = await module.executeCommandAsync(
        SetProductBaseUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-6',
          selection: const ExistingTenantUnit('unit-lo'),
        ),
      );

      expect(result.baseUnitName, 'Lọ');
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
    });

    test('scn_contract_e04_u01_fr01_03 creates new tenant unit and assigns', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.setBaseUnitCreateNew,
      );

      final result = await module.executeCommandAsync(
        SetProductBaseUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-6',
          selection: const NewTenantUnit('Túi'),
        ),
      );

      expect(result.baseUnitName, 'Túi');

      final units = await module.executeQueryAsync(
        ListTenantMeasurementUnitsQuery(tenantId: 'tenant-1'),
      );
      expect(units.map((unit) => unit.name), contains('Túi'));
    });

    test('scn_contract_e04_u01_fr01_04 rejects duplicate unit name', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.setBaseUnitDuplicate,
      );

      final isDuplicate = await module.executeQueryAsync(
        CheckDuplicateMeasurementUnitNameQuery(
          tenantId: 'tenant-1',
          name: 'Lọ',
        ),
      );
      expect(isDuplicate, isTrue);

      await expectLater(
        module.executeCommandAsync(
          SetProductBaseUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            selection: const NewTenantUnit('Lọ'),
          ),
        ),
        throwsA(isA<DuplicateMeasurementUnitNameException>()),
      );
    });

    test('scn_contract_e04_u01_fr01_05 rejects inactive tenant unit', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.setBaseUnitInactiveUnit,
      );

      await expectLater(
        module.executeCommandAsync(
          SetProductBaseUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            selection: const ExistingTenantUnit('unit-inactive'),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_contract_e04_u01_fr02_01 blocks stock without base unit', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.unitDependenciesLocked,
      );

      await expectLater(
        module.executeCommandAsync(
          SetInitialStockCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            quantity: 10.0,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
    });

    test('scn_contract_e04_u01_fr02_02 shows readiness blocker and set_base_unit action', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.unitDependenciesLocked,
      );

      final view = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: 'product-6',
        ),
      );

      expect(
        view.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingBaseUnit),
      );
      expect(view.primaryActionId, ContextualActionId.setBaseUnit);
    });

    test('scn_contract_e04_u01_fr03_01 clears readiness blocker after set base unit', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.setBaseUnitExisting,
      );

      final before = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: 'product-6',
        ),
      );
      expect(
        before.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingBaseUnit),
      );

      await module.executeCommandAsync(
        SetProductBaseUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-6',
          selection: const ExistingTenantUnit('unit-lo'),
        ),
      );

      final after = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: 'product-6',
        ),
      );
      expect(
        after.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
    });
  });

  group('EPIC-04 / US-02 conversion unit contract', () {
    test('scn_contract_e04_u02_fr01_01 adds conversion unit', () async {
      final module = FakeCatalogModule();

      final result = await module.executeCommandAsync(
        AddProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          unitName: 'Thùng',
          conversionRateToBase: 100,
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.unit.name, 'Thùng');
      expect(result.unit.conversionRateToBase, 100);
      expect(result.unit.isBaseUnit, isFalse);
      expect(result.unit.isActive, isTrue);

      final units = await module.executeQueryAsync(
        ListProductUnitsQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          includeInactive: true,
        ),
      );
      expect(units.baseUnitName, 'Hộp');
      expect(
        units.units.where((unit) => unit.name == 'Thùng' && unit.isActive),
        hasLength(1),
      );
    });

    test('scn_contract_e04_u02_fr01_02 rejects add without base unit', () async {
      final module = FakeCatalogModule();

      await expectLater(
        module.executeCommandAsync(
          AddProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            unitName: 'Hộp',
            conversionRateToBase: 10,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
    });

    test('scn_contract_e04_u02_fr01_03 rejects invalid conversion rate', () async {
      final module = FakeCatalogModule();

      await expectLater(
        module.executeCommandAsync(
          AddProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            unitName: 'Thùng',
            conversionRateToBase: 0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_contract_e04_u02_fr01_04 rejects duplicate active or base unit', () async {
      final module = FakeCatalogModule();

      await expectLater(
        module.executeCommandAsync(
          AddProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            unitName: 'Vỉ',
            conversionRateToBase: 10,
          ),
        ),
        throwsA(isA<DuplicateMeasurementUnitNameException>()),
      );

      await expectLater(
        module.executeCommandAsync(
          AddProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            unitName: 'Hộp',
            conversionRateToBase: 1,
          ),
        ),
        throwsA(isA<DuplicateMeasurementUnitNameException>()),
      );
    });

    test('scn_contract_e04_u02_fr03_01 deactivates conversion unit', () async {
      final module = FakeCatalogModule();

      final result = await module.executeCommandAsync(
        DeactivateProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          productUnitId: 'product-1-unit-vi',
        ),
      );

      expect(result.unit.isActive, isFalse);

      final units = await module.executeQueryAsync(
        ListProductUnitsQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          includeInactive: true,
        ),
      );
      final deactivated = units.units.singleWhere(
        (unit) => unit.id == 'product-1-unit-vi',
      );
      expect(deactivated.isActive, isFalse);
    });

    test('scn_contract_e04_u02_fr03_02 rejects deactivating base unit', () async {
      final module = FakeCatalogModule();

      await expectLater(
        module.executeCommandAsync(
          DeactivateProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            productUnitId: 'product-1-base',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_contract_e04_u02_fr04_01 reactivates conversion unit', () async {
      final module = FakeCatalogModule();

      final result = await module.executeCommandAsync(
        ReactivateProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          productUnitId: 'product-1-unit-thung',
        ),
      );

      expect(result.unit.name, 'Thùng');
      expect(result.unit.isActive, isTrue);
    });

    test('scn_contract_e04_u02_fr04_02 rejects duplicate active on reactivate', () async {
      final module = FakeCatalogModule();

      await module.executeCommandAsync(
        AddProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          unitName: 'Thùng',
          conversionRateToBase: 100,
        ),
      );

      await expectLater(
        module.executeCommandAsync(
          ReactivateProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            productUnitId: 'product-1-unit-thung',
          ),
        ),
        throwsA(isA<DuplicateMeasurementUnitNameException>()),
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

  group('EPIC-05 / US-01..02 stock contract', () {
    test('scn_contract_e05_u01_fr01_01 stock profile basic source label', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U01Fr01_01,
      );

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.stock.mode, StockMode.basic);
      expect(result.stock.source, StockDataSource.basicProfile);
      expect(result.stock.sourceLabel, 'Tồn kho cơ bản');
      expect(result.stock.canAdjust, isTrue);
    });

    test('scn_contract_e05_u01_fr02_01 advanced stock read-only source', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.readinessAdvancedStockPending,
      );

      final created = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc stock advanced',
          baseUnitName: 'Lọ',
        ),
      );

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: created.productId,
        ),
      );

      expect(result.stock.mode, StockMode.advanced);
      expect(result.stock.source, StockDataSource.inventoryModule);
      expect(result.stock.sourceLabel, 'Tồn kho từ module Kho');
      expect(result.stock.canAdjust, isFalse);
      expect(result.stock.isPendingExternal, isTrue);
    });

    test('scn_contract_e05_u01_fr03_01 zero quantity is out-of-stock, configured', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U01Fr03_01,
      );

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-3',
        ),
      );

      expect(result.stock.isConfigured, isTrue);
      expect(result.stock.isOutOfStock, isTrue);
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingStock)),
      );
    });

    test('scn_contract_e05_u02_fr01_01 set initial stock returns readiness summary', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U02Fr01_01,
      );

      final result = await module.executeCommandAsync(
        SetInitialStockCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          quantity: 250.0,
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.quantity, 250.0);
      expect(result.readinessSummary.status, isNotNull);
    });

    test('scn_contract_e05_u02_fr01_02 set initial stock without base unit fails', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U02Fr01_02,
      );

      await expectLater(
        module.executeCommandAsync(
          SetInitialStockCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            quantity: 10.0,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
    });

    test('scn_contract_e05_u02_fr02_01 adjust basic stock success', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U02Fr02_01,
      );

      final result = await module.executeCommandAsync(
        AdjustBasicStockCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          newQuantity: 25.0,
          reason: 'Kiểm kê thực tế',
          expectedQuantity: 150.0,
        ),
      );

      expect(result.previousQuantity, 150.0);
      expect(result.newQuantity, 25.0);
    });

    test('scn_contract_e05_u02_fr02_02 adjust basic stock negative rejected', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U02Fr02_02,
      );

      await expectLater(
        module.executeCommandAsync(
          AdjustBasicStockCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            newQuantity: -1.0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_contract_e05_u02_fr02_03 stale quantity rejected', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U02Fr02_03,
      );

      await expectLater(
        module.executeCommandAsync(
          AdjustBasicStockCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            newQuantity: 20.0,
            expectedQuantity: 999.0,
          ),
        ),
        throwsA(isA<StaleStockQuantityException>()),
      );
    });

    test('scn_contract_e05_u02_fr03_01 get stock history movements', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U02Fr03_01,
      );

      await module.executeCommandAsync(
        SetInitialStockCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          quantity: 50.0,
        ),
      );
      await module.executeCommandAsync(
        AdjustBasicStockCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          newQuantity: 45.0,
          expectedQuantity: 50.0,
          reason: 'Điều chỉnh kho',
        ),
      );

      final history = await module.executeQueryAsync(
        GetProductStockHistoryQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(history.movements, isNotEmpty);
      expect(history.movements.first.movementType, StockMovementType.initial);
      expect(history.movements.last.movementType, StockMovementType.adjust);
    });

    test('scn_contract_e05_u02_fr04_01 readiness refreshes after stock update', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE05U02Fr04_01,
      );

      final created = await module.executeCommandAsync(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc mới có đơn vị',
          baseUnitName: 'Lọ',
        ),
      );

      final result = await module.executeCommandAsync(
        SetInitialStockCommand(
          tenantId: 'tenant-1',
          productId: created.productId,
          quantity: 20.0,
        ),
      );

      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingStock)),
      );
    });
  });

  group('EPIC-06 / US-01 manual base price contract', () {
    test('scn_contract_e06_u01_fr01_01 manual mode card on product-1', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U01Fr01_01,
      );

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.basePrice.mode, BasePriceMode.manual);
      expect(result.basePrice.sourceLabel, 'Nhập thủ công');
      expect(result.basePrice.amount, 80000);
      expect(result.basePrice.baseUnitName, 'Hộp');
      expect(result.basePrice.canEdit, isTrue);
      expect(result.basePrice.isMissing, isFalse);
    });

    test('scn_contract_e06_u01_fr01_02 costing mode card is pending external', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U01Fr01_02,
      );

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-8',
        ),
      );

      expect(result.basePrice.mode, BasePriceMode.costingModule);
      expect(result.basePrice.sourceLabel, 'Từ module Giá vốn');
      expect(result.basePrice.isPendingExternal, isTrue);
      expect(result.basePrice.canEdit, isFalse);
    });

    test('scn_contract_e06_u01_fr01_03 manual mode missing base price', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U01Fr01_03,
      );

      final result = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-7',
        ),
      );

      expect(result.basePrice.mode, BasePriceMode.manual);
      expect(result.basePrice.isMissing, isTrue);
      expect(result.basePrice.missingMessage, 'Thiếu Giá cơ sở định giá');
      expect(result.basePrice.baseUnitName, 'Lọ');
    });

    test('scn_contract_e06_u01_fr02_01 set manual base price returns result', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U01Fr02_01,
      );

      final result = await module.executeCommandAsync(
        SetManualBasePriceCommand(
          tenantId: 'tenant-1',
          productId: 'product-7',
          basePrice: 75000.0,
        ),
      );

      expect(result.productId, 'product-7');
      expect(result.basePrice, 75000.0);
      expect(result.unitName, 'Lọ');
      expect(result.readinessSummary.blockers.map((b) => b.code), isNot(contains(ReadinessBlockerCode.missingPrice)));
    });

    test('scn_contract_e06_u01_fr02_02 missing base unit rejected', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U01Fr02_02,
      );

      await expectLater(
        module.executeCommandAsync(
          SetManualBasePriceCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            basePrice: 50000.0,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
    });

    test('scn_contract_e06_u01_fr02_03 negative base price rejected', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U01Fr02_03,
      );

      await expectLater(
        module.executeCommandAsync(
          SetManualBasePriceCommand(
            tenantId: 'tenant-1',
            productId: 'product-7',
            basePrice: -1.0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_contract_e06_u01_fr04_01 readiness clears missing_price after set', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U01Fr04_01,
      );

      final before = await module.executeQueryAsync(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: 'product-7',
        ),
      );
      expect(
        before.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingPrice),
      );

      final result = await module.executeCommandAsync(
        SetManualBasePriceCommand(
          tenantId: 'tenant-1',
          productId: 'product-7',
          basePrice: 60000.0,
        ),
      );

      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingPrice)),
      );
    });
  });

  group('EPIC-06 / US-02 contract', () {
    test('scn_contract_e06_u02_fr01_01 creates store price rule', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr01_01,
      );

      final result = await module.executeCommandAsync(
        SetStorePriceRuleCommand(
          tenantId: 'tenant-new',
          name: 'Mặc định bán lẻ',
          listMarkupRatio: 0.4,
          floorMarkupRatio: 0.2,
        ),
      );

      expect(result.rule.name, 'Mặc định bán lẻ');
      expect(result.rule.listMarkupRatio, 0.4);
      expect(result.rule.status, StorePriceRuleStatus.active);
    });

    test('scn_contract_e06_u02_fr01_02 rejects invalid markup ratio', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr01_02,
      );

      await expectLater(
        module.executeCommandAsync(
          SetStorePriceRuleCommand(
            tenantId: 'tenant-1',
            name: 'Invalid rule',
            listMarkupRatio: -0.1,
            floorMarkupRatio: 0.2,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_contract_e06_u02_fr01_03 returns null when tenant has no rule', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr01_03,
      );

      final rule = await module.executeQueryAsync(
        GetStorePriceRuleQuery(tenantId: 'tenant-no-rule'),
      );

      expect(rule, isNull);
    });

    test('scn_contract_e06_u02_fr01_04 can deactivate store price rule', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr01_04,
      );

      final result = await module.executeCommandAsync(
        SetStorePriceRuleCommand(
          tenantId: 'tenant-1',
          name: 'Mặc định bán lẻ',
          listMarkupRatio: 0.5,
          floorMarkupRatio: 0.25,
          status: StorePriceRuleStatus.inactive,
        ),
      );

      expect(result.rule.status, StorePriceRuleStatus.inactive);
    });

    test('scn_contract_e06_u02_fr02_01 suggests list and floor from base price', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr02_01,
      );

      final suggestion = await module.executeQueryAsync(
        SuggestProductUnitPriceQuery(
          tenantId: 'tenant-1',
          productId: 'product-4',
        ),
      );

      expect(suggestion.canSuggest, isTrue);
      expect(suggestion.suggestedListPrice, 37500);
      expect(suggestion.suggestedFloorPrice, 31250);
      expect(suggestion.storePriceRuleName, 'Mặc định bán lẻ');
    });

    test('scn_contract_e06_u02_fr02_02 cannot suggest without base price', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr02_02,
      );

      final suggestion = await module.executeQueryAsync(
        SuggestProductUnitPriceQuery(
          tenantId: 'tenant-1',
          productId: 'product-7',
        ),
      );

      expect(suggestion.canSuggest, isFalse);
      expect(suggestion.unavailableReason, contains('Giá cơ sở'));
    });

    test('scn_contract_e06_u02_fr02_03 inactive rule cannot suggest', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr02_03,
      );

      final suggestion = await module.executeQueryAsync(
        SuggestProductUnitPriceQuery(
          tenantId: 'tenant-1',
          productId: 'product-4',
        ),
      );

      expect(suggestion.canSuggest, isFalse);
      expect(suggestion.unavailableReason, contains('không hoạt động'));
    });

    test('scn_contract_e06_u02_fr03_01 applies rule to product without band', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr03_01,
      );

      final result = await module.executeCommandAsync(
        ApplyStorePriceRuleCommand(
          tenantId: 'tenant-1',
          productId: 'product-4',
        ),
      );

      expect(result.listPrice, 37500);
      expect(result.floorPrice, 31250);
      expect(result.sourceType, PriceBandSourceType.ruleBased);
    });

    test('scn_contract_e06_u02_fr03_02 requires confirm to overwrite band', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr03_02,
      );

      await expectLater(
        module.executeCommandAsync(
          ApplyStorePriceRuleCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<PriceBandOverwriteRequiredException>()),
      );
    });

    test('scn_contract_e06_u02_fr03_03 rejects stale base price version', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr03_03,
      );

      await expectLater(
        module.executeCommandAsync(
          ApplyStorePriceRuleCommand(
            tenantId: 'tenant-1',
            productId: 'product-4',
            basePriceVersion: 0,
          ),
        ),
        throwsA(isA<StaleBasePriceException>()),
      );
    });

    test('scn_contract_e06_u02_fr04_01 pcc shows custom override label', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U02Fr04_01,
      );

      final pcc = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-2',
        ),
      );

      expect(pcc.priceBand.isCustomOverride, isTrue);
      expect(pcc.priceBand.sourceType, PriceBandSourceType.manual);
    });
  });
}
