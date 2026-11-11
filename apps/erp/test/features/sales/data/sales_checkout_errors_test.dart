import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_checkout_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

const _twelve = [
  'CHECKOUT_BLOCKED',
  'STALE_VERSION',
  'IDEMPOTENCY_CONFLICT',
  'DEPENDENCY_UNAVAILABLE',
  'UNCERTAIN_RESULT',
  'PRODUCT_NOT_SELLABLE',
  'PERMISSION_DENIED',
  'DATA_SCOPE_DENIED',
  'CONTEXT_INVALID',
  'CHECKOUT_RESULT_NOT_FOUND',
  'PRICE_CHANGED',
  'PRICING_BLOCKED',
  'INSUFFICIENT_STOCK',
];

PostgrestException _pg(String code, [String message = 'x']) =>
    PostgrestException(message: '{"code":"$code","message":"$message"}');

void main() {
  group('new', () {
    for (final code in _twelve) {
      final expected = code == 'PERMISSION_DENIED' ? 'NO_PERMISSION' : code;
      test('keeps $code', () {
        final e = salesCheckoutException(_pg(code, 'm'));
        expect(e.code, expected);
        expect(e.serverMessage, 'm');
      });
    }
    test('NOT_FOUND → SYSTEM_ERROR', () {
      expect(salesCheckoutException(_pg('NOT_FOUND')).code, 'SYSTEM_ERROR');
    });
    test('boom → SYSTEM_ERROR', () {
      expect(salesCheckoutException(PostgrestException(message: 'boom')).code, 'SYSTEM_ERROR');
    });
    test('NETWORK_ERROR stays', () {
      expect(salesCheckoutException(const AppException('NETWORK_ERROR')).code, 'NETWORK_ERROR');
    });
    test('uncertainOnNetwork: network and timeout → UNCERTAIN_RESULT', () {
      expect(
        salesCheckoutException(const AppException('NETWORK_ERROR'), uncertainOnNetwork: true).code,
        'UNCERTAIN_RESULT',
      );
      expect(
        salesCheckoutException(TimeoutException('t'), uncertainOnNetwork: true).code,
        'UNCERTAIN_RESULT',
      );
    });
    test('FormatException / StateError → SYSTEM_ERROR', () {
      expect(salesCheckoutException(const FormatException('x')).code, 'SYSTEM_ERROR');
      expect(salesCheckoutException(StateError('x')).code, 'SYSTEM_ERROR');
    });
    test('CONTEXT_INVALID AppException kept', () {
      final e = salesCheckoutException(
        const AppException(
          'CONTEXT_INVALID',
          serverMessage: 'Checkout line quantity must be positive.',
        ),
      );
      expect(e.code, 'CONTEXT_INVALID');
      expect(e.serverMessage, 'Checkout line quantity must be positive.');
    });
    test('nested JSON 2 layers', () {
      final e = salesCheckoutException(
        PostgrestException(message: '{"message":"{\\"code\\":\\"STALE_VERSION\\"}"}'),
      );
      expect(e.code, 'STALE_VERSION');
    });
  });
}
