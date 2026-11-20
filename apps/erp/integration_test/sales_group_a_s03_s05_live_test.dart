import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/models.dart' as sales;
import 'package:erp/features/sales/presentation.dart';

import 'package:erp/features/sales/presentation/lookups/sales_catalog_product_lookup.dart';
import 'package:erp/features/sales/presentation/lookups/sales_pricing_lookup.dart';
import 'package:erp/main.dart' as app;

const _enabledValue = String.fromEnvironment('C45_RUN_LIVE_GROUP_A');
const _enabled = _enabledValue == '1' || _enabledValue == 'true';
const _tenantId = String.fromEnvironment('C45_E2E_TENANT_ID');
const _storeId = String.fromEnvironment('C45_E2E_STORE_ID');
const _customerId = String.fromEnvironment('C45_E2E_CUSTOMER_ID');
const _productId = String.fromEnvironment('C45_E2E_PRODUCT_ID');
const _productUnitId = String.fromEnvironment('C45_E2E_PRODUCT_UNIT_ID');

void main() {
  testWidgets(
    'live Group A uses active store, Catalog, Pricing, and cleans its private rule',
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
      expect(await di<SessionController>().requireTenantId(), _tenantId);
      expect(await di<SessionController>().requireActiveStoreId(), _storeId);

      final products = await SalesCatalogProductLookup.bindSearch(di)(
        _productId,
        limit: 10,
      );
      final product = products.singleWhere((item) => item.productId == _productId);
      final barcode = product.barcode;
      expect(barcode, isNotNull);
      expect(barcode, isNotEmpty);
      final barcodeMatches = await SalesCatalogProductLookup.bindBarcode(di)(barcode!);
      expect(barcodeMatches.any((item) => item.productId == _productId), isTrue);

      final resolvedProduct = await SalesCatalogProductLookup.bindUnits(di)(product);
      final unit = resolvedProduct.selectableUnits.singleWhere(
        (item) => item.productUnitId == _productUnitId,
      );
      final listPrice = unit.unitPrice.amountMinor;
      final livePreview = SalesPricingLookup.bindPreview(di);

      final firstPreviewStarted = Completer<void>();
      final releaseFirstPreview = Completer<void>();
      final firstPreviewFinished = Completer<void>();
      var previewCalls = 0;
      final cubit = SalesComposeCubit(
        draftId: 'draft-new',
        persistDraft: (_) async => throw StateError('must not persist'),
        restoreDraft: (_) async => throw StateError('must not restore'),
        prepareCheckout: (_) async => throw StateError('must not checkout'),
        applyManualPriceFlow:
            ({
              required SalesComposeState state,
              required SalesComposeLineVm line,
              required SalesManualPriceDraft draft,
              required SalesConfirmFn confirmBelowFloor,
              required SalesConfirmFn confirmOverwrite,
            }) async => throw StateError('must not adjust price'),
        previewPricing: (request) async {
          previewCalls += 1;
          final callNumber = previewCalls;
          if (callNumber == 1) {
            firstPreviewStarted.complete();
            await releaseFirstPreview.future;
          }
          try {
            return await livePreview(request);
          } finally {
            if (callNumber == 1 && !firstPreviewFinished.isCompleted) {
              firstPreviewFinished.complete();
            }
          }
        },
      );
      addTearDown(() async {
        if (!releaseFirstPreview.isCompleted) releaseFirstPreview.complete();
        if (!cubit.isClosed) await cubit.close();
      });
      await cubit.hydrate();
      cubit.applyCustomerSelection(
        const SalesCustomerSelection(
          isWalkIn: false,
          displayName: 'Live E2E customer',
          partnerId: _customerId,
        ),
      );
      cubit.addOrIncrementLine(
        SalesProductSelection.fromProductUnit(
          product: resolvedProduct,
          unit: unit,
        ),
      );
      await firstPreviewStarted.future.timeout(const Duration(seconds: 30));
      final lineId = cubit.state.lines.single.identity.lineId;
      expect(cubit.updateQuantity(lineId, 2), isNull);
      final latestVersion = cubit.state.pricingContextVersion;
      await _waitForPricing(cubit, latestVersion);
      expect(cubit.state.lines.single.input.quantity, 2);
      expect(cubit.state.canCheckout, isTrue);

      releaseFirstPreview.complete();
      await firstPreviewFinished.future.timeout(const Duration(seconds: 30));
      expect(cubit.state.pricedContextVersion, latestVersion);
      expect(cubit.state.lines.single.input.quantity, 2);

      cubit.applyManualPrice(
        lineId,
        SalesManualPriceDraft(
          mode: SalesPriceAdjustMode.percentOff,
          acceptedUnitPrice: unit.unitPrice,
          manualUnitPriceMinor: null,
          manualDiscountMinor: null,
          manualDiscountBasisPoints: 10001,
          saveAsPrivatePrice: false,
        ),
      );
      await _waitForPricing(cubit, cubit.state.pricingContextVersion);
      expect(
        cubit.state.lines.single.pricing.blockingCodes,
        contains('MANUAL_PRICE_INVALID'),
      );
      expect(cubit.state.canCheckout, isFalse);

      final request = SalesPricingPreviewRequest(
        customerId: _customerId,
        currencyCode: 'VND',
        contextVersion: 1,
        effectiveAt: DateTime.now().toUtc(),
        lines: [
          SalesPricingLineRequest(
            localLineId: 'live-line',
            productId: _productId,
            productUnitId: _productUnitId,
            quantityMicros: 1000000,
          ),
        ],
      );
      final preview = await SalesPricingLookup.bindPreview(di)(request);
      expect(preview.lines.single.blockingCodes, isEmpty);

      final manual = await SalesPricingLookup.bindEvaluate(di)(
        SalesManualPriceRequest(
          customerId: _customerId,
          productId: _productId,
          productUnitId: _productUnitId,
          quantityMicros: 1000000,
          currencyCode: 'VND',
          contextVersion: 2,
          manualUnitPriceMinor: listPrice,
          manualDiscountMinor: null,
          manualDiscountBasisPoints: null,
          acknowledgeBelowFloor: false,
        ),
      );
      expect(manual.allowed, isTrue);

      final sessionId = 'live-${DateTime.now().microsecondsSinceEpoch}';
      final create = await SalesPricingLookup.bindSavePrivate(di)(
        SalesPrivatePriceSaveRequest(
          composeSessionId: sessionId,
          sourceLineId: 'live-line',
          manualIntentRevision: 1,
          customerId: _customerId,
          productId: _productId,
          productUnitId: _productUnitId,
          acceptedUnitPrice: manual.normalizedUnitPrice,
          currencyCode: 'VND',
          effectiveFrom: DateTime.now().toUtc(),
          contextVersion: 2,
          acknowledgeFloorWarning: false,
          confirmOverwrite: false,
        ),
      );
      expect(create.created, isTrue, reason: 'seed must not reuse a private rule');

      var cleanupVersion = create.version!;
      try {
        final updatePrice = sales.MoneyDto(
          amountMinor: listPrice + 1,
          currencyCode: 'VND',
        );
        final update = await SalesPricingLookup.bindSavePrivate(di)(
          SalesPrivatePriceSaveRequest(
            composeSessionId: sessionId,
            sourceLineId: 'live-line',
            manualIntentRevision: 2,
            customerId: _customerId,
            productId: _productId,
            productUnitId: _productUnitId,
            acceptedUnitPrice: updatePrice,
            currencyCode: 'VND',
            effectiveFrom: DateTime.now().toUtc(),
            contextVersion: 3,
            acknowledgeFloorWarning: false,
            confirmOverwrite: true,
          ),
        );
        expect(update.ruleId, create.ruleId);
        expect(update.version, greaterThanOrEqualTo(create.version!));
        cleanupVersion = update.version!;
      } finally {
        await di<SupabaseRpc>().call(
          'pricing',
          'delete_customer_price_rule',
          params: <String, dynamic>{
            'p_tenant_id': _tenantId,
            'p_rule_id': create.ruleId!,
            'p_expected_version': cleanupVersion,
          },
        );
      }
    },
    skip: !_enabled,
  );
}

Future<void> _waitForPricing(SalesComposeCubit cubit, int contextVersion) async {
  bool isCurrent(SalesComposeState state) =>
      state.pricingStatus == SalesComposePricingStatus.ready &&
      state.pricedContextVersion == contextVersion;

  if (isCurrent(cubit.state)) return;
  await cubit.stream.firstWhere(isCurrent).timeout(const Duration(seconds: 30));
}
