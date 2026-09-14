import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

import '../support/compose_line_test_data.dart';

void main() {
  group('SalesCheckoutDraftArgsMapper', () {
    test('maps complete priced compose state into immutable checkout snapshot', () {
      final state = SalesComposeLoaded(
        draftId: 'draft-7',
        customer: const SalesComposeCustomerVm(
          displayName: 'Phòng khám A',
          phone: '0903000000',
          partnerId: 'partner-7',
        ),
        lines: <SalesComposeLineVm>[_pricedLine()],
        pricing: const SalesComposePricingSlice(
          status: SalesComposePricingStatus.ready,
          contextVersion: 4,
          pricedContextVersion: 4,
        ),
        draftVersion: 3,
      );

      final snapshot = _fromCompose(state);

      expect(snapshot.runtimeDraftId, 'draft-7');
      expect(snapshot.sourceDraftId, 'draft-7');
      expect(snapshot.customerId, 'partner-7');
      expect(snapshot.currencyCode, 'VND');
      expect(snapshot.expectedSourceVersion, 3);
      expect(snapshot.provisionalTotalAmountMinor, 250000);
      expect(snapshot.lines.single.productId, 'product-1');
      expect(snapshot.lines.single.quantity.quantityMicros, 2000000);
      expect(snapshot.lines.single.unitPrice!.amountMinor, 125000);
    });

    test('walk-in maps customerId to null', () {
      final state = SalesComposeLoaded(
        draftId: 'draft-walk-in',
        customer: SalesComposeCustomerVm.walkIn(),
        lines: <SalesComposeLineVm>[_pricedLine()],
        pricing: const SalesComposePricingSlice(
          status: SalesComposePricingStatus.ready,
          contextVersion: 4,
          pricedContextVersion: 4,
        ),
        draftVersion: 1,
      );

      final snapshot = _fromCompose(state);

      expect(snapshot.customerId, isNull);
      expect(snapshot.sourceDraftId, 'draft-walk-in');
      expect(snapshot.isWalkIn, isTrue);
      expect(snapshot.customerDisplayName, 'Khách lẻ');
    });

    test('runtime-only compose state does not claim a persisted source draft', () {
      final state = SalesComposeLoaded(
        draftId: 'runtime-only',
        customer: const SalesComposeCustomerVm(
          displayName: 'Phòng khám A',
          partnerId: 'partner-7',
        ),
        lines: <SalesComposeLineVm>[_pricedLine()],
        pricing: const SalesComposePricingSlice(
          status: SalesComposePricingStatus.ready,
          contextVersion: 4,
          pricedContextVersion: 4,
        ),
      );

      final snapshot = _fromCompose(state);

      expect(snapshot.sourceDraftId, isNull);
      expect(snapshot.customerId, 'partner-7');
    });

    test('list mutation cannot affect the snapshot', () {
      final mutableLines = <SalesComposeLineVm>[_pricedLine()];
      final state = SalesComposeLoaded(
        draftId: 'draft-immutable',
        customer: const SalesComposeCustomerVm(
          displayName: 'Phòng khám A',
          partnerId: 'partner-7',
        ),
        lines: mutableLines,
        pricing: const SalesComposePricingSlice(
          status: SalesComposePricingStatus.ready,
          contextVersion: 4,
          pricedContextVersion: 4,
        ),
        draftVersion: 2,
      );

      final snapshot = _fromCompose(state);

      mutableLines.clear();
      expect(snapshot.lines, hasLength(1));
      expect(snapshot.lines.single.productId, 'product-1');
      expect(
        () => snapshot.lines.add(
          CheckoutLineInput(
            productId: 'product-x',
            productUnitId: 'unit-x',
            quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('stale or unpriced compose state throws StateError', () {
      final stale = SalesComposeLoaded(
        draftId: 'draft-stale',
        customer: const SalesComposeCustomerVm(
          displayName: 'Phòng khám A',
          partnerId: 'partner-7',
        ),
        lines: <SalesComposeLineVm>[_pricedLine(pricedContextVersion: 3)],
        pricing: const SalesComposePricingSlice(
          status: SalesComposePricingStatus.stale,
          contextVersion: 4,
          pricedContextVersion: 3,
        ),
        draftVersion: 1,
      );

      expect(
        () => _fromCompose(stale),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Checkout requires a current priced compose state.',
          ),
        ),
      );
    });

    test('empty lines throw StateError', () {
      final empty = SalesComposeLoaded(
        draftId: 'draft-empty',
        customer: const SalesComposeCustomerVm(
          displayName: 'Phòng khám A',
          partnerId: 'partner-7',
        ),
        lines: const <SalesComposeLineVm>[],
        pricing: const SalesComposePricingSlice(
          status: SalesComposePricingStatus.ready,
          contextVersion: 0,
          pricedContextVersion: 0,
        ),
      );

      expect(
        () => _fromCompose(empty),
        throwsA(isA<StateError>()),
      );
    });

    test('mixed currencies throw StateError', () {
      final mixed = SalesComposeLoaded(
        draftId: 'draft-mixed',
        customer: const SalesComposeCustomerVm(
          displayName: 'Phòng khám A',
          partnerId: 'partner-7',
        ),
        lines: <SalesComposeLineVm>[
          _pricedLine(),
          _pricedLine(
            lineId: 'line-2',
            productId: 'product-2',
            productUnitId: 'unit-2',
            currencyCode: 'USD',
            amountMinor: 10,
          ),
        ],
        pricing: const SalesComposePricingSlice(
          status: SalesComposePricingStatus.ready,
          contextVersion: 4,
          pricedContextVersion: 4,
        ),
        draftVersion: 1,
      );

      expect(
        () => _fromCompose(mixed),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Checkout lines must use one currency.',
          ),
        ),
      );
    });

    test('captures authoritative commercial display snapshot at compose boundary', () {
      final state = SalesComposeLoaded(
        draftId: 'draft-commercial',
        customer: const SalesComposeCustomerVm(
          displayName: 'Nguyễn Văn An',
          partnerId: 'customer-1',
        ),
        lines: <SalesComposeLineVm>[
          _pricedLine(productName: 'Vaccine A', unitLabel: 'Lọ'),
        ],
        pricing: const SalesComposePricingSlice(
          status: SalesComposePricingStatus.ready,
          contextVersion: 4,
          pricedContextVersion: 4,
        ),
      );

      final snapshot = SalesCheckoutDraftArgsMapper.fromCompose(
        state,
        store: const StoreSnapshotDto(
          storeId: 'store-1',
          storeCode: 'HCM-01',
          displayName: 'Chi nhánh Quận 1',
        ),
        seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
      );

      expect(snapshot.commercialSnapshot.store.displayName, 'Chi nhánh Quận 1');
      expect(snapshot.commercialSnapshot.seller.displayName, 'Minh Anh');
      expect(snapshot.commercialSnapshot.lines.single.product.displayName, 'Vaccine A');
      expect(snapshot.commercialSnapshot.lines.single.product.sku, isNull);
      expect(snapshot.commercialSnapshot.lines.single.unit.unitCode, isNull);
      expect(snapshot.commercialSnapshot.customer?.displayName, 'Nguyễn Văn An');
    });
  });
}

SalesCheckoutDraftArgs _fromCompose(SalesComposeState state) =>
    SalesCheckoutDraftArgsMapper.fromCompose(
      state,
      store: const StoreSnapshotDto(
        storeId: 'store-1',
        storeCode: 'HCM-01',
        displayName: 'Chi nhánh Quận 1',
      ),
      seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
    );

SalesComposeLineVm _pricedLine({
  String lineId = 'line-1',
  String productId = 'product-1',
  String productUnitId = 'unit-1',
  int quantity = 2,
  int amountMinor = 125000,
  String currencyCode = 'VND',
  int pricedContextVersion = 4,
  String productName = 'Product',
  String unitLabel = 'viên',
}) {
  final unitPrice = composeTestMoney(amountMinor, currencyCode: currencyCode);
  return composeTestLine(
    lineId: lineId,
    productId: productId,
    productUnitId: productUnitId,
    productName: productName,
    unitLabel: unitLabel,
    quantity: quantity,
    baseUnitPrice: unitPrice,
    appliedUnitPrice: unitPrice,
    listUnitPrice: unitPrice,
    pricedLineTotalMinor: amountMinor * quantity,
    pricedContextVersion: pricedContextVersion,
  );
}
