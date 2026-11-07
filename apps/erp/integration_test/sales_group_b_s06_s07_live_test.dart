import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/lookups/sales_catalog_product_lookup.dart';
import 'package:erp/features/sales/presentation/lookups/sales_partner_customer_lookup.dart';
import 'package:erp/features/sales/presentation/lookups/sales_pricing_lookup.dart';
import 'package:erp/features/sales/logic/sales_draft_backend.dart';
import 'package:erp/main.dart' as app;

const _enabledValue = String.fromEnvironment('VET45_RUN_LIVE_GROUP_B');
const _enabled = _enabledValue == '1' || _enabledValue == 'true';
const _tenantId = String.fromEnvironment('VET45_E2E_TENANT_ID');
const _storeId = String.fromEnvironment('VET45_E2E_STORE_ID');
const _customerId = String.fromEnvironment('VET45_E2E_CUSTOMER_ID');
const _productId = String.fromEnvironment('VET45_E2E_PRODUCT_ID');
const _productUnitId = String.fromEnvironment('VET45_E2E_PRODUCT_UNIT_ID');

void main() {
  testWidgets(
    'live Group B S06-S07 draft lifecycle: save/list/restore/update/idempotent/stale/cancel',
    (tester) async {
      for (final entry in {
        'tenant': _tenantId,
        'store': _storeId,
        'customer': _customerId,
        'product': _productId,
        'productUnit': _productUnitId,
      }.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} seed is required');
      }

      await app.main();
      await tester.pumpAndSettle();
      final di = GetIt.instance;
      final executionContext = di<IExecutionContext>();
      final sales = di<SalesDraftRepository>();
      final tenantId = await executionContext.requireTenantId();
      final storeId = await di<SessionController>().requireActiveStoreId();
      expect(tenantId, _tenantId);
      expect(storeId, _storeId);

      final idempotencyPrefix = 'live-group-b-${DateTime.now().toUtc().microsecondsSinceEpoch}';

      final customerSelection = await SalesPartnerCustomerLookup.bindResolve(di)(
        _customerId,
      );
      expect(customerSelection.isWalkIn, isFalse);
      expect(customerSelection.partnerId, _customerId);

      final products = await SalesCatalogProductLookup.bindSearch(di)(
        _productId,
        limit: 10,
      );
      final product = products.singleWhere((item) => item.productId == _productId);
      final resolvedProduct = await SalesCatalogProductLookup.bindUnits(di)(product);
      final unit = resolvedProduct.selectableUnits.singleWhere(
        (item) => item.productUnitId == _productUnitId,
      );
      final selection = SalesProductSelection.fromProductUnit(
        product: resolvedProduct,
        unit: unit,
      );

      final listPriceMinor = selection.unitPrice.amountMinor;
      expect(listPriceMinor, greaterThan(0));

      final preview = await SalesPricingLookup.bindPreview(di)(
        SalesPricingPreviewRequest(
          customerId: _customerId,
          currencyCode: 'VND',
          contextVersion: 1,
          effectiveAt: DateTime.now().toUtc(),
          lines: [
            SalesPricingLineRequest(
              localLineId: 'live-preview-line',
              productId: _productId,
              productUnitId: _productUnitId,
              quantityMicros: QuantityDto.scale,
              manualUnitPriceMinor: listPriceMinor,
            ),
          ],
        ),
      );
      expect(preview.lines, isNotEmpty);
      expect(preview.lines.single.blockingCodes, isEmpty);
      expect(preview.previewToken, isNotEmpty);

      final manual = await SalesPricingLookup.bindEvaluate(di)(
        SalesManualPriceRequest(
          customerId: _customerId,
          productId: _productId,
          productUnitId: _productUnitId,
          quantityMicros: QuantityDto.scale,
          currencyCode: 'VND',
          contextVersion: 2,
          manualUnitPriceMinor: listPriceMinor,
          manualDiscountMinor: null,
          manualDiscountBasisPoints: null,
          acknowledgeBelowFloor: false,
        ),
      );
      expect(manual.allowed, isTrue);

      final composeCustomer = SalesComposeCustomerVm.fromSelection(
        customerSelection,
      );
      final line = SalesComposeLineVm.composed(
        identity: ComposeLineIdentity(
          lineId: 'live-line-1',
          productId: selection.productId,
          productUnitId: selection.productUnitId,
          productName: selection.productName,
          unitLabel: selection.unitLabel,
          catalogUnitPrice: selection.unitPrice,
        ),
        input: ComposeLineUserInput(
          quantity: 1,
          manual: ComposeManualPricing(
            unitPriceMinor: manual.normalizedUnitPrice.amountMinor,
          ),
        ),
        pricing: ComposeLinePricingReady(
          contextVersion: 0,
          amounts: ComposePricedAmounts(
            listUnitPrice: selection.listUnitPrice ?? selection.unitPrice,
            appliedUnitPrice: manual.normalizedUnitPrice,
            unitDiscount: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
            lineTotal: MoneyDto(
              amountMinor: manual.normalizedUnitPrice.amountMinor,
              currencyCode: 'VND',
            ),
            floorUnitPrice: selection.floorUnitPrice,
          ),
          meta: const ComposePricingMeta(sourceCode: 'MANUAL'),
        ),
        stock: selection.stockQuantity == null
            ? null
            : ComposeLineStockHint(availableQuantity: selection.stockQuantity),
      );

      final persist = SalesDraftBackend.bindPersist(di);
      final restore = SalesDraftBackend.bindRestore(di);

      String? ownedDraftId;
      var ownedVersion = 0;

      Future<void> softCancelOwnedDraft() async {
        final draftId = ownedDraftId;
        if (draftId == null || draftId.isEmpty) return;
        try {
          await sales.cancel(
            draftId: draftId,
            storeId: storeId,
            expectedVersion: ownedVersion,
            idempotencyKey: '$idempotencyPrefix:cleanup:v$ownedVersion',
          );
        } on AppException catch (error) {
          // Already cancelled / converted / missing — do not widen cleanup.
          if (error.code == 'STALE_DATA' || error.code == 'REFERENCE_UNAVAILABLE') {
            return;
          }
          rethrow;
        } finally {
          ownedDraftId = null;
        }
      }

      try {
        final saved = await persist(
          SalesDraftPersistRequest(
            composeSessionId: idempotencyPrefix,
            customer: composeCustomer,
            currencyCode: 'VND',
            orderNote: 'Live Group B note',
            pricingPreviewToken: preview.previewToken,
            pricingContextVersion: preview.contextVersion,
            lines: [line],
          ),
        );
        ownedDraftId = saved.draftId;
        ownedVersion = saved.version;

        expect(saved.version, 1);
        expect(saved.status, SalesDraftStatus.active);
        expect(saved.storeId, storeId);
        expect(saved.total.amountMinor, greaterThan(0));
        expect(saved.customer?.customerId, _customerId);
        expect(saved.orderNote, 'Live Group B note');
        expect(saved.lines, hasLength(1));
        expect(saved.lines.single.productId, _productId);
        expect(saved.lines.single.productUnitId, _productUnitId);
        expect(saved.lines.single.manualUnitPriceMinor, isNotNull);

        final listed = await sales.list(storeId: storeId, pageSize: 50);
        expect(
          listed.items.any((item) => item.draft.draftId == saved.draftId),
          isTrue,
          reason: 'saved draft must appear in active store list',
        );

        final restored = await restore(saved.draftId);
        expect(restored.draft.draftId, saved.draftId);
        expect(restored.draft.version, 1);
        expect(restored.customer.partnerId, _customerId);
        expect(restored.orderNote, 'Live Group B note');
        expect(restored.lines, hasLength(1));
        expect(restored.lines.single.identity.productId, _productId);
        expect(restored.lines.single.identity.productUnitId, _productUnitId);
        expect(
          restored.lines.single.input.manual.unitPriceMinor,
          manual.normalizedUnitPrice.amountMinor,
        );
        expect(
          restored.draft.lines.single.appliedUnitPrice.amountMinor,
          greaterThan(0),
        );

        final updateLines = [
          _lineInputFromDraftLine(
            restored.draft.lines.single,
            quantity: 2,
          ),
        ];
        final updateKey = '$idempotencyPrefix:update';
        final updateHash = '$idempotencyPrefix:update-hash';
        final updateNote = 'Live Group B note updated';

        final updated = await sales.update(
          draftId: saved.draftId,
          storeId: storeId,
          customer: CustomerSnapshotDto(
            customerId: _customerId,
            displayName: customerSelection.displayName,
            phoneNumber: customerSelection.phone,
          ),
          currencyCode: 'VND',
          orderNote: updateNote,
          pricingPreviewToken: restored.draft.pricingPreviewToken,
          needsRevalidation: restored.draft.needsRevalidation,
          lines: updateLines,
          expectedVersion: restored.draft.version,
          idempotencyKey: updateKey,
          payloadHash: updateHash,
        );
        ownedVersion = updated.version;
        expect(updated.version, greaterThan(restored.draft.version));
        expect(updated.orderNote, updateNote);
        expect(updated.lines.single.quantity.quantityMicros, 2 * QuantityDto.scale);

        final retried = await sales.update(
          draftId: saved.draftId,
          storeId: storeId,
          customer: CustomerSnapshotDto(
            customerId: _customerId,
            displayName: customerSelection.displayName,
            phoneNumber: customerSelection.phone,
          ),
          currencyCode: 'VND',
          orderNote: updateNote,
          pricingPreviewToken: restored.draft.pricingPreviewToken,
          needsRevalidation: restored.draft.needsRevalidation,
          lines: updateLines,
          expectedVersion: restored.draft.version,
          idempotencyKey: updateKey,
          payloadHash: updateHash,
        );
        expect(retried.version, updated.version);
        expect(retried.draftId, updated.draftId);
        ownedVersion = retried.version;

        await expectLater(
          sales.update(
            draftId: saved.draftId,
            storeId: storeId,
            customer: CustomerSnapshotDto(
              customerId: _customerId,
              displayName: customerSelection.displayName,
              phoneNumber: customerSelection.phone,
            ),
            currencyCode: 'VND',
            orderNote: 'stale attempt',
            pricingPreviewToken: restored.draft.pricingPreviewToken,
            needsRevalidation: restored.draft.needsRevalidation,
            lines: updateLines,
            expectedVersion: restored.draft.version,
            idempotencyKey: '$idempotencyPrefix:stale',
            payloadHash: '$idempotencyPrefix:stale-hash',
          ),
          throwsA(
            isA<AppException>().having(
              (error) => error.code,
              'code',
              'STALE_DATA',
            ),
          ),
        );

        final cancelled = await sales.cancel(
          draftId: saved.draftId,
          storeId: storeId,
          expectedVersion: ownedVersion,
          idempotencyKey: '$idempotencyPrefix:cancel:v$ownedVersion',
        );
        expect(cancelled.status, SalesDraftStatus.cancelled);
        ownedVersion = cancelled.version;
        ownedDraftId = null;

        final afterCancel = await sales.list(storeId: storeId, pageSize: 50);
        expect(
          afterCancel.items.any((item) => item.draft.draftId == saved.draftId),
          isFalse,
          reason: 'cancelled draft must leave the active list',
        );
      } finally {
        await softCancelOwnedDraft();
      }
    },
    skip: !_enabled,
  );
}

SalesOrderDraftLineInput _lineInputFromDraftLine(
  SalesOrderDraftLineDto line, {
  required int quantity,
}) {
  final qty = quantity < 1 ? 1 : quantity;
  return SalesOrderDraftLineInput(
    productId: line.productId,
    productSku: line.productSku,
    productName: line.productName,
    productUnitId: line.productUnitId,
    unitCode: line.unitCode,
    unitName: line.unitName,
    quantity: QuantityDto(quantityMicros: qty * QuantityDto.scale),
    appliedUnitPrice: line.appliedUnitPrice,
    lineTotal: MoneyDto(
      amountMinor: line.appliedUnitPrice.amountMinor * qty,
      currencyCode: line.appliedUnitPrice.currencyCode,
    ),
    listUnitPrice: line.listUnitPrice,
    manualUnitPriceMinor: line.manualUnitPriceMinor,
    manualDiscountMinor: line.manualDiscountMinor,
    manualDiscountBasisPoints: line.manualDiscountBasisPoints,
    pricingSourceCode: line.pricingSourceCode,
    pricingWarningCodes: line.pricingWarningCodes,
    pricingBlockingCodes: line.pricingBlockingCodes,
    note: line.note,
    needsRevalidation: line.needsRevalidation,
  );
}
