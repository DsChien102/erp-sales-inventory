import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

import '../support/compose_cubit_test_stubs.dart';

void main() {
  group('SalesComposeCubit pricing state machine', () {
    test('empty cart is pricing-ready but cannot checkout', () async {
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        previewPricing: (_) => throw StateError('must not call preview'),
      );
      addTearDown(cubit.close);

      await cubit.hydrate();

      expect(cubit.state.pricingStatus, SalesComposePricingStatus.ready);
      expect(cubit.state.pricingContextVersion, 0);
      expect(cubit.state.pricedContextVersion, 0);
      expect(cubit.state.canCheckout, isFalse);
    });

    test('customer, line, quantity, and manual changes increment version', () async {
      final requests = <SalesPricingPreviewRequest>[];
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        quantityPricingDebounceDuration: Duration.zero,
        previewPricing: (request) async {
          requests.add(request);
          return _successFor(request);
        },
      );
      addTearDown(cubit.close);
      await cubit.hydrate();

      cubit.setCustomer(
        const SalesComposeCustomerVm(
          displayName: 'Khach A',
          partnerId: 'customer-1',
        ),
      );
      expect(cubit.state.pricingContextVersion, 1);

      cubit.addOrIncrementLine(_selection);
      await _flush();
      expect(cubit.state.pricingContextVersion, 2);

      expect(cubit.updateQuantity(cubit.state.lines.single.identity.lineId, 2), isNull);
      await _flush();
      expect(cubit.state.pricingContextVersion, 3);

      cubit.applyUnitPrice(
        cubit.state.lines.single.identity.lineId,
        const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
      );
      await _flush();
      expect(cubit.state.pricingContextVersion, 4);
      expect(cubit.state.lines.single.input.manual.unitPriceMinor, 90000);
      expect(requests.last.contextVersion, 4);
      expect(requests.last.lines.single.manualUnitPriceMinor, 90000);
    });

    test('refresh sends complete immutable snapshot and applies complete result', () async {
      late SalesPricingPreviewRequest captured;
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        quantityPricingDebounceDuration: Duration.zero,
        previewPricing: (request) async {
          captured = request;
          return _successFor(
            request,
            appliedMinor: 120000,
            totalMinor: 240000,
            warningCodes: const ['LOW_MARGIN'],
          );
        },
      );
      addTearDown(cubit.close);
      await cubit.hydrate();
      cubit.setCustomer(
        const SalesComposeCustomerVm(
          displayName: 'Khach A',
          partnerId: 'customer-1',
        ),
      );
      cubit.addOrIncrementLine(_selection);
      await _flush();
      final lineId = cubit.state.lines.single.identity.lineId;
      cubit.updateQuantity(lineId, 2);
      await _flush();

      expect(captured.customerId, 'customer-1');
      expect(captured.currencyCode, 'VND');
      expect(captured.lines.single.localLineId, lineId);
      expect(captured.lines.single.productId, 'product-1');
      expect(captured.lines.single.productUnitId, 'unit-1');
      expect(captured.lines.single.quantityMicros, 2000000);

      final line = cubit.state.lines.single;
      expect(line.pricing.appliedUnitPrice.amountMinor, 120000);
      expect(line.lineTotalMinor, 240000);
      expect(line.pricing.warningCodes, const ['LOW_MARGIN']);
      expect(line.pricing.contextVersion, cubit.state.pricingContextVersion);
      expect(cubit.state.previewToken, isNotEmpty);
      expect(cubit.state.canCheckout, isTrue);
    });

    test('stale overlapping response cannot regress current pricing', () async {
      final first = Completer<SalesPricingPreviewResult>();
      final second = Completer<SalesPricingPreviewResult>();
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        quantityPricingDebounceDuration: Duration.zero,
        previewPricing: (request) => request.contextVersion == 1 ? first.future : second.future,
      );
      addTearDown(cubit.close);
      await cubit.hydrate();

      cubit.addOrIncrementLine(_selection);
      final lineId = cubit.state.lines.single.identity.lineId;
      cubit.updateQuantity(lineId, 2);
      final currentRequest = SalesPricingPreviewRequest(
        customerId: null,
        currencyCode: 'VND',
        contextVersion: 2,
        effectiveAt: DateTime.utc(2026, 8, 11),
        lines: [
          SalesPricingLineRequest(
            localLineId: lineId,
            productId: 'product-1',
            productUnitId: 'unit-1',
            quantityMicros: 2000000,
          ),
        ],
      );
      second.complete(_successFor(currentRequest, appliedMinor: 120000));
      await _flush();
      expect(cubit.state.pricedContextVersion, 2);
      expect(cubit.state.lines.single.pricing.appliedUnitPrice.amountMinor, 120000);

      first.complete(
        _successFor(
          SalesPricingPreviewRequest(
            customerId: null,
            currencyCode: 'VND',
            contextVersion: 1,
            effectiveAt: DateTime.utc(2026, 8, 11),
            lines: [
              SalesPricingLineRequest(
                localLineId: lineId,
                productId: 'product-1',
                productUnitId: 'unit-1',
                quantityMicros: 1000000,
              ),
            ],
          ),
          appliedMinor: 80000,
        ),
      );
      await _flush();

      expect(cubit.state.pricedContextVersion, 2);
      expect(cubit.state.lines.single.pricing.appliedUnitPrice.amountMinor, 120000);
    });

    test('rapid quantity changes debounce to the latest pricing request', () async {
      final requests = <SalesPricingPreviewRequest>[];
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        quantityPricingDebounceDuration: const Duration(milliseconds: 20),
        previewPricing: (request) async {
          requests.add(request);
          return _successFor(request);
        },
      );
      addTearDown(cubit.close);
      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();
      requests.clear();

      final lineId = cubit.state.lines.single.identity.lineId;
      expect(cubit.updateQuantity(lineId, 2), isNull);
      expect(cubit.updateQuantity(lineId, 3), isNull);
      expect(cubit.updateQuantity(lineId, 4), isNull);
      await _flush();

      expect(cubit.state.lines.single.input.quantity, 4);
      expect(cubit.state.pricingStatus, SalesComposePricingStatus.stale);
      expect(requests, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      await _flush();

      expect(requests, hasLength(1));
      expect(requests.single.lines.single.quantityMicros, 4000000);
      expect(cubit.state.pricingStatus, SalesComposePricingStatus.ready);
    });

    test('missing or duplicate response line becomes pricing error', () async {
      for (final duplicate in [false, true]) {
        final cubit = composeTestCubit(
          draftId: 'draft-new',
          persistDraft: (_) async => throw StateError('must not persist'),
          restoreDraft: (_) async => throw StateError('must not restore'),
          previewPricing: (request) async => SalesPricingPreviewResult(
            contextVersion: request.contextVersion,
            previewToken: 'bad-token',
            currencyCode: 'VND',
            lines: duplicate
                ? [
                    _lineResult(request.lines.single),
                    _lineResult(request.lines.single),
                  ]
                : const [],
          ),
        );
        addTearDown(cubit.close);
        await cubit.hydrate();
        cubit.addOrIncrementLine(_selection);
        await _flush();

        expect(cubit.state.pricingStatus, SalesComposePricingStatus.error);
        expect(cubit.state.canCheckout, isFalse);
      }
    });

    test('blocker disables checkout, warning does not', () async {
      var blocked = true;
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        previewPricing: (request) async => _successFor(
          request,
          blockingCodes: blocked ? const ['FLOOR_OVERRIDE_REQUIRED'] : const [],
          warningCodes: blocked ? const [] : const ['BELOW_FLOOR'],
        ),
      );
      addTearDown(cubit.close);
      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();
      expect(cubit.state.canCheckout, isFalse);

      blocked = false;
      await cubit.refreshPricingPreview();
      expect(cubit.state.lines.single.pricing.warningCodes, const ['BELOW_FLOOR']);
      expect(cubit.state.canCheckout, isTrue);
    });

    test('transport error preserves user intent and disables checkout', () async {
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        previewPricing: (_) async => throw StateError('offline'),
      );
      addTearDown(cubit.close);
      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      final lineId = cubit.state.lines.single.identity.lineId;
      cubit.applyUnitPrice(
        lineId,
        const MoneyDto(amountMinor: 91000, currencyCode: 'VND'),
      );
      await _flush();

      expect(cubit.state.lines.single.input.manual.unitPriceMinor, 91000);
      expect(cubit.state.pricingStatus, SalesComposePricingStatus.error);
      expect(cubit.state.canCheckout, isFalse);
    });

    test('changeLineUnit keeps quantity and refreshes pricing context', () async {
      final requests = <SalesPricingPreviewRequest>[];
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        quantityPricingDebounceDuration: Duration.zero,
        previewPricing: (request) async {
          requests.add(request);
          return _successFor(request);
        },
      );
      addTearDown(cubit.close);
      await cubit.hydrate();

      cubit.addOrIncrementLine(_selection);
      await _flush();
      final lineId = cubit.state.lines.single.identity.lineId;
      cubit.updateQuantity(lineId, 3);
      await _flush();
      final versionBefore = cubit.state.pricingContextVersion;

      final err = cubit.changeLineUnit(
        lineId,
        const SalesProductSelection(
          productId: 'product-1',
          productUnitId: 'unit-2',
          productName: 'San pham 1',
          sku: 'SP-1',
          unitLabel: 'Lo',
          unitPrice: MoneyDto(amountMinor: 12000, currencyCode: 'VND'),
          listUnitPrice: MoneyDto(amountMinor: 12000, currencyCode: 'VND'),
          stockQuantity: 10,
        ),
      );
      await _flush();

      expect(err, isNull);
      expect(cubit.state.lines, hasLength(1));
      final line = cubit.state.lines.single;
      expect(line.identity.lineId, lineId);
      expect(line.identity.productUnitId, 'unit-2');
      expect(line.identity.unitLabel, 'Lo');
      expect(line.input.quantity, 3);
      expect(line.input.manual.isEmpty, isTrue);
      expect(cubit.state.pricingContextVersion, versionBefore + 1);
      expect(requests.last.lines.single.productUnitId, 'unit-2');
      expect(requests.last.lines.single.quantityMicros, 3000000);
    });

    test('changeLineUnit merges into existing product+unit line', () async {
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        quantityPricingDebounceDuration: Duration.zero,
        previewPricing: (request) async => _successFor(request),
      );
      addTearDown(cubit.close);
      await cubit.hydrate();

      cubit.addOrIncrementLine(_selection);
      await _flush();
      final unit1LineId = cubit.state.lines.single.identity.lineId;
      cubit.updateQuantity(unit1LineId, 2);
      await _flush();

      cubit.addOrIncrementLine(
        const SalesProductSelection(
          productId: 'product-1',
          productUnitId: 'unit-2',
          productName: 'San pham 1',
          sku: 'SP-1',
          unitLabel: 'Lo',
          unitPrice: MoneyDto(amountMinor: 12000, currencyCode: 'VND'),
          stockQuantity: 10,
        ),
      );
      await _flush();
      expect(cubit.state.lines, hasLength(2));
      final unit2LineId = cubit.state.lines
          .firstWhere((line) => line.identity.productUnitId == 'unit-2')
          .identity
          .lineId;
      cubit.updateQuantity(unit2LineId, 3);
      await _flush();

      final err = cubit.changeLineUnit(
        unit2LineId,
        _selection,
      );
      await _flush();

      expect(err, isNull);
      expect(cubit.state.lines, hasLength(1));
      expect(cubit.state.lines.single.identity.lineId, unit1LineId);
      expect(cubit.state.lines.single.identity.productUnitId, 'unit-1');
      expect(cubit.state.lines.single.input.quantity, 5);
    });

    test('changeLineUnit same unit is a no-op', () async {
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        quantityPricingDebounceDuration: Duration.zero,
        previewPricing: (request) async => _successFor(request),
      );
      addTearDown(cubit.close);
      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();
      final version = cubit.state.pricingContextVersion;
      final lineId = cubit.state.lines.single.identity.lineId;

      expect(cubit.changeLineUnit(lineId, _selection), isNull);
      expect(cubit.state.pricingContextVersion, version);
      expect(cubit.state.lines, hasLength(1));
    });
  });
}

const _selection = SalesProductSelection(
  productId: 'product-1',
  productUnitId: 'unit-1',
  productName: 'San pham 1',
  sku: 'SP-1',
  unitLabel: 'Hop',
  unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
  listUnitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
  floorUnitPrice: MoneyDto(amountMinor: 80000, currencyCode: 'VND'),
  stockQuantity: 10,
);

SalesPricingPreviewResult _successFor(
  SalesPricingPreviewRequest request, {
  int appliedMinor = 100000,
  int? totalMinor,
  List<String> warningCodes = const [],
  List<String> blockingCodes = const [],
}) => SalesPricingPreviewResult(
  contextVersion: request.contextVersion,
  previewToken: 'token-${request.contextVersion}',
  currencyCode: request.currencyCode,
  lines: request.lines
      .map(
        (line) => _lineResult(
          line,
          appliedMinor: appliedMinor,
          totalMinor: totalMinor,
          warningCodes: warningCodes,
          blockingCodes: blockingCodes,
        ),
      )
      .toList(growable: false),
);

SalesPricingLineResult _lineResult(
  SalesPricingLineRequest line, {
  int appliedMinor = 100000,
  int? totalMinor,
  List<String> warningCodes = const [],
  List<String> blockingCodes = const [],
}) => SalesPricingLineResult(
  localLineId: line.localLineId,
  appliedUnitPrice: MoneyDto(
    amountMinor: appliedMinor,
    currencyCode: 'VND',
  ),
  discount: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
  lineTotal: MoneyDto(
    amountMinor: totalMinor ?? appliedMinor * line.quantityMicros ~/ 1000000,
    currencyCode: 'VND',
  ),
  sourceCode: 'LIST_PRICE',
  listUnitPrice: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
  floorUnitPrice: const MoneyDto(amountMinor: 80000, currencyCode: 'VND'),
  warningCodes: warningCodes,
  blockingCodes: blockingCodes,
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);
