import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/main.dart' as app;

const _enabledValue = String.fromEnvironment('VET45_RUN_LIVE_GROUP_C');
const _enabled = _enabledValue == '1' || _enabledValue == 'true';
const _tenantId = String.fromEnvironment('VET45_E2E_TENANT_ID');
const _storeId = String.fromEnvironment('VET45_E2E_STORE_ID');
const _customerId = String.fromEnvironment('VET45_E2E_CUSTOMER_ID');
const _productId = String.fromEnvironment('VET45_E2E_PRODUCT_ID');
const _productUnitId = String.fromEnvironment('VET45_E2E_PRODUCT_UNIT_ID');
const _expectUnavailableValue = String.fromEnvironment(
  'VET45_E2E_GROUP_C_EXPECT_UNAVAILABLE',
  defaultValue: 'true',
);
const _expectUnavailable = _expectUnavailableValue == '1' || _expectUnavailableValue == 'true';

void main() {
  testWidgets(
    'live Group C S08-S11 precheck through SalesCheckoutRepository (fail-closed or ready)',
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
      final sales = di<SalesCheckoutRepository>();
      final tenantId = await executionContext.requireTenantId();
      final storeId = await di<SessionController>().requireActiveStoreId();
      expect(tenantId, _tenantId);
      expect(storeId, _storeId);

      final unitPrice = const MoneyDto(amountMinor: 1000000, currencyCode: 'VND');
      final result = await sales.precheck(
        storeId: storeId,
        customerId: _customerId,
        currencyCode: 'VND',
        lines: [
          CheckoutLineInput(
            productId: _productId,
            productUnitId: _productUnitId,
            quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
            unitPrice: unitPrice,
          ),
        ],
        paymentIntents: [
          PaymentIntentInput(
            method: SalesPaymentMethod.cash,
            amount: unitPrice,
          ),
        ],
      );

      if (_expectUnavailable) {
        expect(
          result.blockers.map((item) => item.code),
          contains('DEPENDENCY_UNAVAILABLE'),
        );
        expect(result.canFinalize, isFalse);
      } else {
        expect(result.blockers, isEmpty);
        expect(result.canFinalize, isTrue);
      }
    },
    skip: !_enabled,
  );
}
