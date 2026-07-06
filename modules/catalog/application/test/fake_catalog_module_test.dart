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
            quantity: 10,
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
