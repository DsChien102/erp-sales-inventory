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

  group('EPIC-03 / US-01 custom field config contract', () {
    test('scn_contract_e03_u01_fr01_01 seeds template groups and fields', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfTemplateSeedOk,
      );

      final result = await module.executeCommandAsync(
        InitializeCustomFieldTemplateCommand(tenantId: 'tenant-1'),
      );

      expect(result.groupsCreated, 2);
      expect(result.fieldsCreated, 3);

      final config = await module.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );
      expect(config.groups, hasLength(2));
      expect(config.groups.first.name, 'Thông tin thuốc');
      expect(config.groups.first.iconKey, '💊');
      expect(config.groups.first.fields, hasLength(2));
    });

    test('scn_contract_e03_u01_fr01_02 re-init does not overwrite edited field', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfTemplateReinitNoOverwrite,
      );

      await module.executeCommandAsync(
        InitializeCustomFieldTemplateCommand(tenantId: 'tenant-1'),
      );

      final configBefore = await module.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );
      final group = configBefore.groups.first;
      final field = group.fields.first;

      await module.executeCommandAsync(
        UpsertCustomFieldCommand(
          tenantId: 'tenant-1',
          groupId: group.groupId,
          fieldId: field.fieldId,
          name: 'Thành phần (đã sửa)',
          fieldType: field.fieldType,
        ),
      );

      final reinit = await module.executeCommandAsync(
        InitializeCustomFieldTemplateCommand(tenantId: 'tenant-1'),
      );

      expect(reinit.skippedCount, greaterThan(0));

      final configAfter = await module.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );
      final updatedField = configAfter.groups
          .expand((g) => g.fields)
          .firstWhere((f) => f.fieldId == field.fieldId);
      expect(updatedField.name, 'Thành phần (đã sửa)');
    });

    test('scn_contract_e03_u01_fr02_01 upserts new group for tenant', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfGroupUpsertOk,
      );

      final group = await module.executeCommandAsync(
        UpsertCustomFieldGroupCommand(
          tenantId: 'tenant-1',
          name: 'Thông tin thuốc',
        ),
      );

      expect(group.groupId, startsWith('cf-group-'));
      expect(group.name, 'Thông tin thuốc');
      expect(group.status, CustomFieldConfigStatus.active);
    });

    test('scn_contract_e03_u01_fr02_02 upserts group with icon', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfGroupUpsertOk,
      );

      final group = await module.executeCommandAsync(
        UpsertCustomFieldGroupCommand(
          tenantId: 'tenant-1',
          name: 'Thông tin thuốc',
          iconKey: '💊',
        ),
      );

      expect(group.iconKey, '💊');
    });

    test('scn_contract_e03_u01_fr02_03 deactivates group preserving data', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfGroupDeactivateOk,
      );

      final created = await module.executeCommandAsync(
        UpsertCustomFieldGroupCommand(
          tenantId: 'tenant-1',
          name: 'Thông tin thuốc',
        ),
      );

      final deactivated = await module.executeCommandAsync(
        UpsertCustomFieldGroupCommand(
          tenantId: 'tenant-1',
          groupId: created.groupId,
          name: 'Thông tin thuốc',
          isActive: false,
        ),
      );

      expect(deactivated.status, CustomFieldConfigStatus.inactive);
      expect(deactivated.name, 'Thông tin thuốc');
    });

    test('scn_contract_e03_u01_fr02_04 rejects duplicate active group name', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfGroupDuplicateName,
      );

      await expectLater(
        module.executeCommandAsync(
          UpsertCustomFieldGroupCommand(
            tenantId: 'tenant-1',
            name: 'Thông tin thuốc',
          ),
        ),
        throwsA(isA<DuplicateCustomFieldGroupNameException>()),
      );
    });

    test('scn_contract_e03_u01_fr03_01 reorders groups in config view', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfReorderGroupsOk,
      );

      await module.executeCommandAsync(
        InitializeCustomFieldTemplateCommand(tenantId: 'tenant-1'),
      );

      final before = await module.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );
      final reorderedIds = before.groups.reversed.map((g) => g.groupId).toList();

      await module.executeCommandAsync(
        ReorderCustomFieldGroupsCommand(
          tenantId: 'tenant-1',
          orderedGroupIds: reorderedIds,
        ),
      );

      final after = await module.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );
      expect(after.groups.map((g) => g.groupId), reorderedIds);
    });

    test('scn_contract_e03_u01_fr04_01 upserts text field in group', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfFieldUpsertText,
      );

      final group = await module.executeCommandAsync(
        UpsertCustomFieldGroupCommand(
          tenantId: 'tenant-1',
          name: 'Thông tin thuốc',
        ),
      );

      final field = await module.executeCommandAsync(
        UpsertCustomFieldCommand(
          tenantId: 'tenant-1',
          groupId: group.groupId,
          name: 'Thành phần',
          fieldType: CustomFieldType.text,
        ),
      );

      expect(field.fieldId, startsWith('cf-field-'));
      expect(field.name, 'Thành phần');
      expect(field.fieldType, CustomFieldType.text);
    });

    test('scn_contract_e03_u01_fr04_02 rejects single select without options', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfFieldSingleSelectNoOptions,
      );

      final group = await module.executeCommandAsync(
        UpsertCustomFieldGroupCommand(
          tenantId: 'tenant-1',
          name: 'Thông tin thuốc',
        ),
      );

      await expectLater(
        module.executeCommandAsync(
          UpsertCustomFieldCommand(
            tenantId: 'tenant-1',
            groupId: group.groupId,
            name: 'Dạng bào chế',
            fieldType: CustomFieldType.singleSelect,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_contract_e03_u01_fr05_01 configure required returns missing count', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfFieldRequiredOn,
      );

      await module.executeCommandAsync(
        InitializeCustomFieldTemplateCommand(tenantId: 'tenant-1'),
      );
      final config = await module.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );
      final fieldId = config.groups.first.fields.first.fieldId;

      final result = await module.executeCommandAsync(
        ConfigureCustomFieldAttributesCommand(
          tenantId: 'tenant-1',
          fieldId: fieldId,
          isRequired: true,
          isSearchable: false,
          isFilterable: false,
          displayOnList: false,
        ),
      );

      expect(result.field.isRequired, isTrue);
      expect(result.existingProductsMissingCount, greaterThan(0));
    });

    test('scn_contract_e03_u01_fr06_01 reorders fields within group', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfReorderFieldsOk,
      );

      await module.executeCommandAsync(
        InitializeCustomFieldTemplateCommand(tenantId: 'tenant-1'),
      );
      final config = await module.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );
      final group = config.groups.first;
      final reorderedFieldIds = group.fields.reversed.map((f) => f.fieldId).toList();

      await module.executeCommandAsync(
        ReorderCustomFieldsCommand(
          tenantId: 'tenant-1',
          groupId: group.groupId,
          orderedFieldIds: reorderedFieldIds,
        ),
      );

      final after = await module.executeQueryAsync(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );
      final updatedGroup = after.groups.firstWhere((g) => g.groupId == group.groupId);
      expect(updatedGroup.fields.map((f) => f.fieldId), reorderedFieldIds);
    });

    test('scn_contract_e03_u01_perm_01 denies without manage permission', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.cfPermissionDenied,
      );

      await expectLater(
        module.executeQueryAsync(
          ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
        ),
        throwsA(isA<ApplicationException>()),
      );
    });
  });

  group('EPIC-03 / US-02 custom field values contract', () {
    Future<({String groupId, String textFieldId, String numberFieldId})>
    seedCustomFieldValuesConfig(FakeCatalogModule module) async {
      final group = await module.executeCommandAsync(
        UpsertCustomFieldGroupCommand(
          tenantId: 'tenant-1',
          name: 'Thông tin thuốc',
          iconKey: 'medication',
        ),
      );
      final textField = await module.executeCommandAsync(
        UpsertCustomFieldCommand(
          tenantId: 'tenant-1',
          groupId: group.groupId,
          name: 'Thành phần',
          fieldType: CustomFieldType.text,
        ),
      );
      final numberField = await module.executeCommandAsync(
        UpsertCustomFieldCommand(
          tenantId: 'tenant-1',
          groupId: group.groupId,
          name: 'Thời gian ngưng sử dụng',
          fieldType: CustomFieldType.number,
        ),
      );
      return (
        groupId: group.groupId,
        textFieldId: textField.fieldId,
        numberFieldId: numberField.fieldId,
      );
    }

    test('scn_contract_e03_u02_fr01_01 renders active groups and fields sorted', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE03U02Fr01_01,
      );

      await module.executeCommandAsync(
        InitializeCustomFieldTemplateCommand(tenantId: 'tenant-1'),
      );

      final values = await module.executeQueryAsync(
        GetProductCustomFieldValuesQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(values.productId, 'product-1');
      expect(values.groups.map((group) => group.name), [
        'Thông tin thuốc',
        'Quy cách & bảo quản',
      ]);
      expect(values.groups.first.fields.map((field) => field.name), [
        'Thành phần',
        'Chỉ định',
      ]);
    });

    test('scn_contract_e03_u02_fr02_01 saves text value and shows it on PCC', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE03U02Fr02_01,
      );
      final config = await seedCustomFieldValuesConfig(module);

      final result = await module.executeCommandAsync(
        UpsertCustomFieldValuesCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          values: [
            ProductCustomFieldValueInput(
              fieldId: config.textFieldId,
              textValue: 'Vitamin A, D, E',
            ),
          ],
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.values.groups.single.fields.first.displayValue, 'Vitamin A, D, E');

      final pcc = await module.executeQueryAsync(
        GetProductControlCenterQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );
      expect(pcc.customFieldGroupCards.single.name, 'Thông tin thuốc');
      expect(pcc.customFieldGroupCards.single.fields.first.displayValue, 'Vitamin A, D, E');
    });

    test('scn_contract_e03_u02_fr02_02 rejects invalid typed values', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE03U02Fr02_02,
      );
      final config = await seedCustomFieldValuesConfig(module);

      await expectLater(
        module.executeCommandAsync(
          UpsertCustomFieldValuesCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            values: [
              ProductCustomFieldValueInput(
                fieldId: config.numberFieldId,
                textValue: 'bảy ngày',
              ),
            ],
          ),
        ),
        throwsA(
          isA<CustomFieldValueValidationException>().having(
            (e) => e.errors.single.fieldId,
            'fieldId',
            config.numberFieldId,
          ),
        ),
      );
    });

    test('scn_contract_e03_u02_fr03_01 reports missing required field at field level', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE03U02Fr03_01,
      );
      final config = await seedCustomFieldValuesConfig(module);

      await module.executeCommandAsync(
        ConfigureCustomFieldAttributesCommand(
          tenantId: 'tenant-1',
          fieldId: config.textFieldId,
          isRequired: true,
          isSearchable: false,
          isFilterable: false,
          displayOnList: false,
        ),
      );

      await expectLater(
        module.executeCommandAsync(
          UpsertCustomFieldValuesCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            values: const [],
          ),
        ),
        throwsA(
          isA<CustomFieldValueValidationException>().having(
            (e) => e.errors.single.message,
            'message',
            'Vui lòng nhập Thành phần',
          ),
        ),
      );
    });

    test('scn_contract_e03_u02_fr03_02 filling required field clears readiness blocker', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE03U02Fr03_02,
      );
      final config = await seedCustomFieldValuesConfig(module);

      await module.executeCommandAsync(
        ConfigureCustomFieldAttributesCommand(
          tenantId: 'tenant-1',
          fieldId: config.textFieldId,
          isRequired: true,
          isSearchable: false,
          isFilterable: false,
          displayOnList: false,
        ),
      );

      final result = await module.executeCommandAsync(
        UpsertCustomFieldValuesCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          values: [
            ProductCustomFieldValueInput(
              fieldId: config.textFieldId,
              textValue: 'Vitamin A, D, E',
            ),
          ],
        ),
      );

      expect(
        result.readinessSummary.blockers.map((blocker) => blocker.code),
        isNot(contains(ReadinessBlockerCode.missingRequiredCustomFields)),
      );
    });

    test('scn_contract_e03_u02_fr04_01 preserves inactive field values', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE03U02Fr04_01,
      );
      final config = await seedCustomFieldValuesConfig(module);

      await module.executeCommandAsync(
        UpsertCustomFieldValuesCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          values: [
            ProductCustomFieldValueInput(
              fieldId: config.textFieldId,
              textValue: 'Dữ liệu cũ',
            ),
          ],
        ),
      );
      await module.executeCommandAsync(
        UpsertCustomFieldCommand(
          tenantId: 'tenant-1',
          groupId: config.groupId,
          fieldId: config.textFieldId,
          name: 'Thành phần',
          fieldType: CustomFieldType.text,
          isActive: false,
        ),
      );

      final activeOnly = await module.executeQueryAsync(
        GetProductCustomFieldValuesQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );
      expect(
        activeOnly.groups.single.fields.map((field) => field.fieldId),
        isNot(contains(config.textFieldId)),
      );

      final withInactive = await module.executeQueryAsync(
        GetProductCustomFieldValuesQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          includeInactiveValues: true,
        ),
      );
      final preserved = withInactive.groups.single.fields.firstWhere(
        (field) => field.fieldId == config.textFieldId,
      );
      expect(preserved.displayValue, 'Dữ liệu cũ');
    });
  });

  group('EPIC-03 / US-03 custom field search contract', () {
    test('scn_contract_e03_u03_fr01_01 exposes display-on-list values', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.customFieldSearchDisplay,
      );

      final result = await module.executeQueryAsync(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(),
        ),
      );

      final product = result.items.firstWhere((item) => item.id == 'product-1');
      expect(
        product.customFieldValues.map((value) => value.fieldName),
        contains('Dạng dùng'),
      );
      expect(
        product.customFieldValues.map((value) => value.displayValue),
        contains('Dung dịch'),
      );
    });

    test('scn_contract_e03_u03_fr03_01 lists filterable custom field options', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.customFieldFilterable,
      );

      final options = await module.executeQueryAsync(
        ListCustomFieldFilterOptionsQuery(tenantId: 'tenant-1'),
      );

      final dosageForm = options.singleWhere(
        (option) => option.fieldName == 'Dạng dùng',
      );
      expect(
        dosageForm.options.map((option) => option.label),
        contains('Dung dịch'),
      );
    });

    test('scn_contract_e03_u03_fr02_01 searches via searchable custom field', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.customFieldSearchable,
      );

      final result = await module.executeQueryAsync(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(keyword: 'tiêu hóa'),
        ),
      );

      expect(result.items.map((item) => item.id), contains('product-1'));
    });

    test('scn_contract_e03_u03_fr03_01 filters by single-select custom field', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.customFieldFilterable,
      );

      final options = await module.executeQueryAsync(
        ListCustomFieldFilterOptionsQuery(tenantId: 'tenant-1'),
      );
      final dosageForm = options.singleWhere(
        (option) => option.fieldName == 'Dạng dùng',
      );
      final solution = dosageForm.options.singleWhere(
        (option) => option.label == 'Dung dịch',
      );

      final result = await module.executeQueryAsync(
        SearchProductsQuery(
          tenantId: 'tenant-1',
          criteria: ProductSearchCriteria(
            customFieldFilters: [
              CustomFieldFilterCriteria(
                fieldId: dosageForm.fieldId,
                optionId: solution.optionId,
              ),
            ],
          ),
        ),
      );

      expect(result.items.map((item) => item.id), contains('product-1'));
      expect(result.items.every((item) => item.id == 'product-1'), isTrue);
    });

    test('scn_contract_e03_u03_fr03_02 excludes inactive filterable config', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.customFieldFilterInactive,
      );

      final options = await module.executeQueryAsync(
        ListCustomFieldFilterOptionsQuery(tenantId: 'tenant-1'),
      );

      expect(options.map((option) => option.fieldName), isNot(contains('Dạng dùng')));
    });

    test('scn_contract_e03_u03_fr04_01 returns product custom field snapshots', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.customFieldSnapshot,
      );

      final snapshot = await module.executeQueryAsync(
        GetProductCustomFieldSnapshotQuery(
          tenantId: 'tenant-1',
          productIds: const ['product-1'],
        ),
      );

      final fields = snapshot.products['product-1'] ?? const [];
      expect(fields.map((field) => field.fieldName), contains('Dạng dùng'));
      expect(fields.map((field) => field.displayValue), contains('Dung dịch'));
    });

    test('scn_contract_e03_u03_permission_denied blocks custom field search reads', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.customFieldSearchPermissionDenied,
      );

      await expectLater(
        module.executeQueryAsync(
          ListCustomFieldFilterOptionsQuery(tenantId: 'tenant-1'),
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
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingPrice)),
      );
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

  group('EPIC-06 / US-03 contract', () {
    test('scn_contract_e06_u03_fr01_01 sets price band on base unit', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr01_01,
      );

      final result = await module.executeCommandAsync(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-4',
          listPrice: 37500,
          floorPrice: 31250,
        ),
      );

      expect(result.productId, 'product-4');
      expect(result.listPrice, 37500);
      expect(result.floorPrice, 31250);
      expect(result.sourceType, PriceBandSourceType.manual);
      expect(
        result.readinessSummary.blockers.any(
          (b) => b.code == ReadinessBlockerCode.missingPriceBand,
        ),
        isFalse,
      );
    });

    test('scn_contract_e06_u03_fr01_02 rejects floor greater than list', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr01_02,
      );

      await expectLater(
        module.executeCommandAsync(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-4',
            listPrice: 100000,
            floorPrice: 110000,
          ),
        ),
        throwsA(isA<FloorPriceGreaterThanListPriceException>()),
      );
    });

    test('scn_contract_e06_u03_fr01_03 lists price bands per active unit', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr01_03,
      );

      final result = await module.executeQueryAsync(
        ListProductUnitPriceBandsQuery(
          tenantId: 'tenant-1',
          productId: 'product-9',
        ),
      );

      expect(result.rows, hasLength(2));
      expect(result.rows.map((row) => row.unitName), containsAll(['Lọ', 'Hộp']));
      expect(result.rows.every((row) => row.isMissing), isTrue);
    });

    test('scn_contract_e06_u03_fr01_04 rejects inactive unit', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr01_04,
      );

      await expectLater(
        module.executeCommandAsync(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            productUnitId: 'product-1-unit-thung',
            listPrice: 1000000,
            floorPrice: 900000,
          ),
        ),
        throwsA(isA<InactiveProductUnitException>()),
      );
    });

    test('scn_contract_e06_u03_fr02_01 requires acknowledgment for warnings', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr02_01,
      );

      await expectLater(
        module.executeCommandAsync(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-11',
            listPrice: 95000,
            floorPrice: 90000,
          ),
        ),
        throwsA(isA<PriceBandWarningsRequireAcknowledgmentException>()),
      );
    });

    test('scn_contract_e06_u03_fr02_02 saves with warnings when confirmed', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr02_02,
      );

      final result = await module.executeCommandAsync(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-11',
          listPrice: 95000,
          floorPrice: 90000,
          confirmAcknowledgeWarnings: true,
        ),
      );

      expect(result.warnings, isNotEmpty);
      expect(
        result.warnings.any((w) => w.code == 'list_price_below_base_price'),
        isTrue,
      );
      expect(result.listPrice, 95000);
    });

    test('scn_contract_e06_u03_fr02_03 warns when conversion rate unknown', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr02_03,
      );

      await expectLater(
        module.executeCommandAsync(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-11',
            productUnitId: 'product-11-hop',
            listPrice: 950000,
            floorPrice: 900000,
          ),
        ),
        throwsA(isA<PriceBandWarningsRequireAcknowledgmentException>()),
      );

      final result = await module.executeCommandAsync(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-11',
          productUnitId: 'product-11-hop',
          listPrice: 950000,
          floorPrice: 900000,
          confirmAcknowledgeWarnings: true,
        ),
      );

      expect(
        result.warnings.any((w) => w.code == 'cannot_compare_base_price'),
        isTrue,
      );
    });

    test('scn_contract_e06_u03_fr03_01 clears missing price band blocker', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr03_01,
      );

      final result = await module.executeCommandAsync(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-4',
          listPrice: 37500,
          floorPrice: 31250,
        ),
      );

      expect(
        result.readinessSummary.blockers.any(
          (b) => b.code == ReadinessBlockerCode.missingPriceBand,
        ),
        isFalse,
      );
    });

    test('scn_contract_e06_u03_fr03_02 keeps blocker when another unit lacks band', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE06U03Fr03_02,
      );

      final result = await module.executeCommandAsync(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-9',
          productUnitId: 'product-9-base',
          listPrice: 15000,
          floorPrice: 12000,
        ),
      );

      expect(
        result.readinessSummary.blockers.any(
          (b) => b.code == ReadinessBlockerCode.missingPriceBand,
        ),
        isTrue,
      );
    });
  });

  group('EPIC-07 / US-01 product profile maintenance contract', () {
    test('scn_contract_e07_u01_fr01_01 updates profile and readiness', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE07U01Fr01_01,
      );

      final result = await module.executeCommandAsync(
        UpdateProductProfileCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-1',
          productName: 'Amoxicillin 500mg hộp mới',
          commercialName: 'Amo 500',
          sku: 'SKU-001-NEW',
          barcode: '8930000000099',
          description: 'Mô tả mới',
          note: 'Ghi chú mới',
          expectedVersion: 1,
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.profile.name, 'Amoxicillin 500mg hộp mới');
      expect(result.profile.tradeName, 'Amo 500');
      expect(result.profile.sku, 'SKU-001-NEW');
      expect(result.profile.barcode, '8930000000099');
      expect(result.profile.description, 'Mô tả mới');
      expect(result.profile.note, 'Ghi chú mới');
      expect(result.version, 2);
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
    });

    test('scn_contract_e07_u01_fr01_02 rejects blank product name', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE07U01Fr01_02,
      );

      await expectLater(
        module.executeCommandAsync(
          UpdateProductProfileCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            productName: '   ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_contract_e07_u01_fr01_03 rejects duplicate sku', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE07U01Fr01_03,
      );

      await expectLater(
        module.executeCommandAsync(
          UpdateProductProfileCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            productName: 'Amoxicillin 500mg',
            sku: 'SP0002',
          ),
        ),
        throwsA(
          isA<DuplicateSkuException>().having(
            (e) => e.existingProductId,
            'existingProductId',
            'product-2',
          ),
        ),
      );
    });

    test(
      'scn_contract_e07_u01_fr03_01 rejects duplicate barcode including inactive product',
      () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U01Fr03_01,
        );

        await expectLater(
          module.executeCommandAsync(
            UpdateProductProfileCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-1',
              productName: 'Amoxicillin 500mg',
              barcode: '8930000000005',
            ),
          ),
          throwsA(
            isA<DuplicateBarcodeException>().having(
              (e) => e.existingProductId,
              'existingProductId',
              'product-5',
            ),
          ),
        );
      },
    );

    test('scn_contract_e07_u01_fr01_04 rejects soft-deleted product updates', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE07U01Fr01_04,
      );

      await expectLater(
        module.executeCommandAsync(
          UpdateProductProfileCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-7',
            productName: 'Soft deleted product',
          ),
        ),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            contains('soft-deleted'),
          ),
        ),
      );
    });

    test('scn_contract_e07_u01_fr01_05 rejects stale expected version', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE07U01Fr01_05,
      );

      await expectLater(
        module.executeCommandAsync(
          UpdateProductProfileCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            productName: 'Amoxicillin 500mg',
            expectedVersion: 0,
          ),
        ),
        throwsA(
          isA<StaleProductVersionException>()
              .having((e) => e.expectedVersion, 'expectedVersion', 0)
              .having((e) => e.currentVersion, 'currentVersion', 1),
        ),
      );
    });

    test('scn_contract_e07_u01_fr02_01 replaces image snapshot and primary', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE07U01Fr02_01,
      );

      final result = await module.executeCommandAsync(
        UpdateProductImagesCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-1',
          images: const [
            ProductImageMutationInput(
              imageId: 'image-new-2',
              storageKey: 'tenant-1/products/product-1/image-new-2.webp',
              url: 'https://cdn.fake/image-new-2.webp',
              isPrimary: true,
              sortOrder: 0,
            ),
            ProductImageMutationInput(
              imageId: 'image-new-1',
              storageKey: 'tenant-1/products/product-1/image-new-1.webp',
              url: 'https://cdn.fake/image-new-1.webp',
              sortOrder: 1,
            ),
          ],
          expectedVersion: 1,
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.images.map((image) => image.imageId), [
        'image-new-2',
        'image-new-1',
      ]);
      expect(result.images.singleWhere((image) => image.isPrimary).imageId, 'image-new-2');
      expect(result.primaryImageUrl, 'https://cdn.fake/image-new-2.webp');
      expect(result.version, 2);
    });

    test(
      'scn_contract_e07_u01_fr02_02 promotes first remaining image when primary is removed',
      () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U01Fr02_02,
        );

        final result = await module.executeCommandAsync(
          UpdateProductImagesCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            images: const [
              ProductImageMutationInput(
                imageId: 'image-remaining',
                storageKey: 'tenant-1/products/product-1/image-remaining.webp',
                url: 'https://cdn.fake/image-remaining.webp',
                sortOrder: 0,
              ),
            ],
          ),
        );

        expect(result.images, hasLength(1));
        expect(result.images.single.isPrimary, isTrue);
        expect(result.primaryImageUrl, 'https://cdn.fake/image-remaining.webp');
      },
    );

    test(
      'scn_contract_e07_u01_fr02_03 allows deleting all images and refreshes readiness',
      () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U01Fr02_03,
        );

        final result = await module.executeCommandAsync(
          UpdateProductImagesCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            images: const [],
          ),
        );

        expect(result.images, isEmpty);
        expect(result.primaryImageUrl, isNull);
        expect(
          result.readinessSummary.blockers.map((b) => b.code),
          contains(ReadinessBlockerCode.missingImage),
        );
      },
    );

    test('scn_contract_e07_u01_fr02_04 rejects invalid maintenance upload type', () async {
      final module = FakeCatalogModule(
        scenario: FakeCatalogScenario.scnContractE07U01Fr02_04,
      );

      await expectLater(
        module.executeCommandAsync(
          RequestProductMaintenanceImageUploadCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            fileName: 'photo.gif',
            contentType: 'image/gif',
            byteSize: 1024,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'scn_contract_e07_u01_fr04_01 returns refreshed readiness after profile and image updates',
      () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U01Fr04_01,
        );

        final profileResult = await module.executeCommandAsync(
          UpdateProductProfileCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-4',
            productName: 'Vitamin B Complex cập nhật',
            sku: 'SKU-004-NEW',
          ),
        );
        final imageResult = await module.executeCommandAsync(
          UpdateProductImagesCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-4',
            images: const [
              ProductImageMutationInput(
                storageKey: 'tenant-1/products/product-4/image-1.webp',
                url: 'https://cdn.fake/product-4-image-1.webp',
                isPrimary: true,
                sortOrder: 0,
              ),
            ],
          ),
        );

        expect(profileResult.readinessSummary.status, ReadinessStatus.incomplete);
        expect(imageResult.readinessSummary.status, ReadinessStatus.incomplete);
        expect(
          imageResult.readinessSummary.blockers.map((b) => b.code),
          isNot(contains(ReadinessBlockerCode.missingImage)),
        );
      },
    );

    group('EPIC-07 / US-02 product business status contract', () {
      test('scn_contract_e07_u02_fr01_01 deactivates active product', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U02Fr01_01,
        );

        final result = await module.executeCommandAsync(
          DeactivateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-4',
            reason: 'Ngừng kinh doanh theo mùa',
          ),
        );

        expect(result.productId, 'product-4');
        expect(result.previousStatus, ProductStatus.active);
        expect(result.currentStatus, ProductStatus.inactive);
        expect(result.reason, 'Ngừng kinh doanh theo mùa');
        expect(result.version, 2);

        final pcc = await module.executeQueryAsync(
          GetProductControlCenterQuery(
            tenantId: 'tenant-1',
            productId: 'product-4',
          ),
        );
        expect(pcc.profile.businessStatus, ProductStatus.inactive);
      });

      test(
        'scn_contract_e07_u02_fr01_02 requires warning acknowledgment for stocked product',
        () async {
          final module = FakeCatalogModule(
            scenario: FakeCatalogScenario.scnContractE07U02Fr01_02,
          );

          await expectLater(
            module.executeCommandAsync(
              DeactivateProductCommand(
                tenantId: 'tenant-1',
                actorId: 'user-1',
                productId: 'product-1',
              ),
            ),
            throwsA(
              isA<ProductBusinessStatusWarningsRequireAcknowledgmentException>().having(
                (e) => e.warnings.map((warning) => warning.code),
                'warning codes',
                contains(ProductBusinessStatusWarningCode.hasStock),
              ),
            ),
          );

          final result = await module.executeCommandAsync(
            DeactivateProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-1',
              confirmAcknowledgeWarnings: true,
            ),
          );

          expect(result.currentStatus, ProductStatus.inactive);
          expect(
            result.warnings.map((warning) => warning.code),
            contains(ProductBusinessStatusWarningCode.hasStock),
          );
        },
      );

      test('scn_contract_e07_u02_fr01_03 denies missing manage status permission', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U02Fr01_03,
        );

        await expectLater(
          module.executeCommandAsync(
            DeactivateProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-4',
            ),
          ),
          throwsA(
            isA<ApplicationException>().having(
              (e) => e.message,
              'message',
              contains('Permission denied'),
            ),
          ),
        );
      });

      test('scn_contract_e07_u02_fr01_04 rejects already inactive product', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U02Fr01_04,
        );

        await expectLater(
          module.executeCommandAsync(
            DeactivateProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-5',
            ),
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('already inactive'),
            ),
          ),
        );
      });

      test('scn_contract_e07_u02_fr02_01 reactivates inactive ready product', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U02Fr02_01,
        );

        final result = await module.executeCommandAsync(
          ReactivateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-5',
            reason: 'Kinh doanh lại',
          ),
        );

        expect(result.previousStatus, ProductStatus.inactive);
        expect(result.currentStatus, ProductStatus.active);
        expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
      });

      test(
        'scn_contract_e07_u02_fr02_02 reactivates incomplete product with blockers',
        () async {
          final module = FakeCatalogModule(
            scenario: FakeCatalogScenario.scnContractE07U02Fr02_02,
          );

          final result = await module.executeCommandAsync(
            ReactivateProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-4',
            ),
          );

          expect(result.currentStatus, ProductStatus.active);
          expect(result.readinessSummary.status, ReadinessStatus.incomplete);
          expect(
            result.readinessSummary.blockers.map((b) => b.code),
            contains(ReadinessBlockerCode.missingPriceBand),
          );
        },
      );

      test('scn_contract_e07_u02_fr02_03 rejects soft-deleted product reactivation', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U02Fr02_03,
        );

        await expectLater(
          module.executeCommandAsync(
            ReactivateProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-7',
            ),
          ),
          throwsA(
            isA<ApplicationException>().having(
              (e) => e.message,
              'message',
              contains('soft-deleted'),
            ),
          ),
        );
      });

      test('scn_contract_e07_u02_fr03_01 search excludes inactive by default', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U02Fr03_01,
        );

        final defaultResult = await module.executeQueryAsync(
          SearchProductsQuery(
            tenantId: 'tenant-1',
            criteria: ProductSearchCriteria(keyword: 'Doxycycline'),
          ),
        );
        expect(defaultResult.items, isEmpty);

        final adminResult = await module.executeQueryAsync(
          SearchProductsQuery(
            tenantId: 'tenant-1',
            criteria: ProductSearchCriteria(
              keyword: 'Doxycycline',
              businessStatuses: {ProductStatus.active, ProductStatus.inactive},
            ),
          ),
        );
        expect(adminResult.items.single.businessStatus, ProductStatus.inactive);
      });

      test(
        'scn_contract_e07_u02_fr04_01 returns status history preview data',
        () async {
          final module = FakeCatalogModule(
            scenario: FakeCatalogScenario.scnContractE07U02Fr04_01,
          );

          final result = await module.executeCommandAsync(
            DeactivateProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-4',
              reason: 'Hết vòng đời sản phẩm',
            ),
          );

          expect(result.historyEntry, isNotNull);
          expect(result.historyEntry!.changeType, 'product_status_changed');
          expect(result.historyEntry!.valueBefore, ProductStatus.active.name);
          expect(result.historyEntry!.valueAfter, ProductStatus.inactive.name);
          expect(result.historyEntry!.summary, contains('Ngừng kinh doanh'));
        },
      );
    });

    group('EPIC-07 / US-03 product soft delete contract', () {
      test(
        'scn_contract_e07_u03_fr01_01 eligibility allows product without dependencies',
        () async {
          final module = FakeCatalogModule(
            scenario: FakeCatalogScenario.scnContractE07U03Fr01_01,
          );

          final result = await module.executeQueryAsync(
            CheckProductDeletionEligibilityQuery(
              tenantId: 'tenant-1',
              productId: 'product-6',
            ),
          );

          expect(result.productId, 'product-6');
          expect(result.canDelete, isTrue);
          expect(result.issues, isEmpty);
          expect(result.suggestedActionId, isNull);
        },
      );

      test('scn_contract_e07_u03_fr01_02 open transaction blocks delete', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr01_02,
        );

        final result = await module.executeQueryAsync(
          CheckProductDeletionEligibilityQuery(
            tenantId: 'tenant-1',
            productId: 'product-4',
          ),
        );

        expect(result.canDelete, isFalse);
        expect(
          result.issues.map((issue) => issue.code),
          contains(ProductDeletionIssueCode.openTransaction),
        );
        expect(
          result.issues.map((issue) => issue.severity),
          contains(ProductDeletionIssueSeverity.blocker),
        );

        await expectLater(
          module.executeCommandAsync(
            DeleteProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-4',
              confirmAcknowledgeWarnings: true,
            ),
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('cannot be deleted'),
            ),
          ),
        );
      });

      test('scn_contract_e07_u03_fr01_03 historical data warns and suggests deactivate', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr01_03,
        );

        final result = await module.executeQueryAsync(
          CheckProductDeletionEligibilityQuery(
            tenantId: 'tenant-1',
            productId: 'product-1',
          ),
        );

        expect(result.canDelete, isTrue);
        expect(result.suggestedActionId, 'deactivate_product');
        expect(
          result.issues.map((issue) => issue.code),
          contains(ProductDeletionIssueCode.hasHistoricalTransactions),
        );
        expect(
          result.issues.map((issue) => issue.severity),
          contains(ProductDeletionIssueSeverity.warning),
        );
      });

      test('scn_contract_e07_u03_fr02_01 delete soft-deletes and writes history', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr02_01,
        );

        final result = await module.executeCommandAsync(
          DeleteProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-6',
            reason: 'Không còn sử dụng',
          ),
        );

        expect(result.productId, 'product-6');
        expect(result.isSoftDeleted, isTrue);
        expect(result.businessStatus, ProductStatus.active);
        expect(result.version, 2);
        expect(result.reason, 'Không còn sử dụng');
        expect(result.historyEntry, isNotNull);
        expect(result.historyEntry!.changeType, 'product_soft_deleted');

        final pcc = await module.executeQueryAsync(
          GetProductControlCenterQuery(
            tenantId: 'tenant-1',
            productId: 'product-6',
          ),
        );
        expect(pcc.profile.isSoftDeleted, isTrue);
        expect(pcc.changeHistoryPreview.first.changeType, 'product_soft_deleted');
      });

      test('scn_contract_e07_u03_fr02_02 stale expected version is rejected', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr02_02,
        );

        await expectLater(
          module.executeCommandAsync(
            DeleteProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-6',
              expectedVersion: 0,
            ),
          ),
          throwsA(
            isA<StaleProductVersionException>()
                .having((e) => e.expectedVersion, 'expectedVersion', 0)
                .having((e) => e.currentVersion, 'currentVersion', 1),
          ),
        );
      });

      test('scn_contract_e07_u03_fr02_03 search excludes soft-deleted by default', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr02_03,
        );

        await module.executeCommandAsync(
          DeleteProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-6',
          ),
        );

        final defaultResult = await module.executeQueryAsync(
          SearchProductsQuery(
            tenantId: 'tenant-1',
            criteria: ProductSearchCriteria(keyword: 'Thuốc thiếu đơn vị'),
          ),
        );
        expect(defaultResult.items, isEmpty);

        final includeDeletedResult = await module.executeQueryAsync(
          SearchProductsQuery(
            tenantId: 'tenant-1',
            criteria: ProductSearchCriteria(
              keyword: 'Thuốc thiếu đơn vị',
              includeSoftDeleted: true,
            ),
          ),
        );
        expect(includeDeletedResult.items.single.isSoftDeleted, isTrue);
      });

      test('scn_contract_e07_u03_fr03_01 restores as inactive with readiness', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr03_01,
        );

        await module.executeCommandAsync(
          DeleteProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-7',
          ),
        );

        final result = await module.executeCommandAsync(
          RestoreProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-7',
            reason: 'Khôi phục do xóa nhầm',
          ),
        );

        expect(result.isSoftDeleted, isFalse);
        expect(result.businessStatus, ProductStatus.inactive);
        expect(result.reason, 'Khôi phục do xóa nhầm');
        expect(result.readinessSummary.status, ReadinessStatus.incomplete);
        expect(
          result.readinessSummary.blockers.map((b) => b.code),
          contains(ReadinessBlockerCode.missingPrice),
        );
        expect(result.historyEntry!.changeType, 'product_restored');
      });

      test('scn_contract_e07_u03_fr03_02 restore duplicate SKU is rejected', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr03_02,
        );

        await expectLater(
          module.executeCommandAsync(
            RestoreProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-7',
            ),
          ),
          throwsA(
            isA<DuplicateSkuException>().having(
              (e) => e.sku,
              'sku',
              'SP0001',
            ),
          ),
        );
      });

      test('scn_contract_e07_u03_fr03_03 restore duplicate barcode is rejected', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr03_03,
        );

        await expectLater(
          module.executeCommandAsync(
            RestoreProductCommand(
              tenantId: 'tenant-1',
              actorId: 'user-1',
              productId: 'product-7',
            ),
          ),
          throwsA(
            isA<DuplicateBarcodeException>().having(
              (e) => e.barcode,
              'barcode',
              '8930000000001',
            ),
          ),
        );
      });

      test('scn_contract_e07_u03_fr04_01 preserved PCC data remains readable', () async {
        final module = FakeCatalogModule(
          scenario: FakeCatalogScenario.scnContractE07U03Fr04_01,
        );

        await module.executeCommandAsync(
          DeleteProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            reason: 'Dọn danh mục',
          ),
        );

        final pcc = await module.executeQueryAsync(
          GetProductControlCenterQuery(
            tenantId: 'tenant-1',
            productId: 'product-1',
          ),
        );

        expect(pcc.profile.isSoftDeleted, isTrue);
        expect(pcc.units.baseUnitName, 'Hộp');
        expect(pcc.stock.quantity, 150);
        expect(pcc.basePrice.amount, 80000);
        expect(pcc.priceBand.listPrice, 120000);
        expect(
          pcc.changeHistoryPreview.map((entry) => entry.changeType),
          contains('product_soft_deleted'),
        );
      });
    });
  });
}
