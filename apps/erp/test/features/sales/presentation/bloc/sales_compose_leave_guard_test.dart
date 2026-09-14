import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

import '../support/compose_cubit_test_stubs.dart';

void main() {
  group('SalesComposeState.shouldConfirmLeave', () {
    test('customer-only unsaved does not require leave confirm', () async {
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        previewPricing: (_) => throw StateError('must not call preview'),
      );
      addTearDown(cubit.close);
      await cubit.hydrate();

      cubit.setCustomer(
        const SalesComposeCustomerVm(
          displayName: 'Cty TNHH 1 Mình Tao',
          partnerId: 'customer-1',
          phone: '09812312312',
        ),
      );

      expect(cubit.state.hasUnsavedChanges, isTrue);
      expect(cubit.state.lines, isEmpty);
      expect(cubit.state.shouldConfirmLeave, isFalse);
    });

    test('order-note-only unsaved does not require leave confirm', () async {
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        previewPricing: (_) => throw StateError('must not call preview'),
      );
      addTearDown(cubit.close);
      await cubit.hydrate();

      cubit.setOrderNote('Giao buổi sáng');

      expect(cubit.state.hasUnsavedChanges, isTrue);
      expect(cubit.state.lines, isEmpty);
      expect(cubit.state.shouldConfirmLeave, isFalse);
    });

    test('unsaved with lines requires leave confirm', () async {
      final requests = <SalesPricingPreviewRequest>[];
      final cubit = composeTestCubit(
        draftId: 'draft-new',
        previewPricing: (request) async {
          requests.add(request);
          return SalesPricingPreviewResult(
            contextVersion: request.contextVersion,
            previewToken: 'token-${request.contextVersion}',
            currencyCode: request.currencyCode,
            lines: request.lines
                .map(
                  (line) => SalesPricingLineResult(
                    localLineId: line.localLineId,
                    appliedUnitPrice: const MoneyDto(
                      amountMinor: 100000,
                      currencyCode: 'VND',
                    ),
                    discount: const MoneyDto(
                      amountMinor: 0,
                      currencyCode: 'VND',
                    ),
                    lineTotal: MoneyDto(
                      amountMinor: 100000 * line.quantityMicros ~/ 1000000,
                      currencyCode: 'VND',
                    ),
                    sourceCode: 'LIST_PRICE',
                    listUnitPrice: const MoneyDto(
                      amountMinor: 100000,
                      currencyCode: 'VND',
                    ),
                    floorUnitPrice: const MoneyDto(
                      amountMinor: 80000,
                      currencyCode: 'VND',
                    ),
                    warningCodes: const [],
                    blockingCodes: const [],
                  ),
                )
                .toList(growable: false),
          );
        },
      );
      addTearDown(cubit.close);
      await cubit.hydrate();

      cubit.addOrIncrementLine(
        const SalesProductSelection(
          productId: 'product-1',
          productUnitId: 'unit-1',
          productName: 'Thuốc A',
          sku: 'SP-1',
          unitLabel: 'Hộp',
          unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.lines, isNotEmpty);
      expect(cubit.state.hasUnsavedChanges, isTrue);
      expect(cubit.state.shouldConfirmLeave, isTrue);
    });
  });
}
