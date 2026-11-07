// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/return_exchange_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  group('returnExchangeException', () {
    test('extracts code and serverMessage from PostgrestException json', () {
      final exc = returnExchangeException(
        const PostgrestException(message: '{"code":"STALE_VERSION","message":"x"}'),
      );
      expect(exc.code, 'STALE_VERSION');
      expect(exc.serverMessage, 'x');
    });

    test('normalizes PERMISSION_DENIED to NO_PERMISSION', () {
      final exc = returnExchangeException(
        const PostgrestException(message: '{"code":"PERMISSION_DENIED","message":"denied"}'),
      );
      expect(exc.code, 'NO_PERMISSION');
    });

    for (final code in <String>{
      'NOT_FOUND',
      'NO_PERMISSION',
      'DATA_SCOPE_DENIED',
      'RETURN_EXCHANGE_BLOCKED',
      'RETURN_QUANTITY_EXCEEDED',
      'STALE_VERSION',
      'PRICE_CHANGED',
      'PRICING_BLOCKED',
      'IDEMPOTENCY_CONFLICT',
      'IMPACT_PENDING',
      'DEPENDENCY_UNAVAILABLE',
      'COMPETING_CANCELLATION',
      'CONTEXT_INVALID',
      'IN_PROGRESS',
      'INVALID_QUANTITY',
      'PRODUCT_NOT_SELLABLE',
      'PROJECTION_PENDING',
      'NETWORK_ERROR',
    }) {
      test('preserves $code', () {
        final exc = returnExchangeException(AppException(code));
        expect(exc.code, code);
      });
    }

    test('preserves details in RETURN_EXCHANGE_BLOCKED', () {
      final exc = returnExchangeException(
        const PostgrestException(
          message:
              '{"code":"RETURN_EXCHANGE_BLOCKED","details":{"blockers":[{"code":"X","message":"m"}]}}',
        ),
      );
      expect(exc.code, 'RETURN_EXCHANGE_BLOCKED');
      expect(exc.details?['blockers'], isA<List>());
      expect((exc.details!['blockers'] as List).length, 1);
    });

    test('maps weird unknown code to SYSTEM_ERROR', () {
      final exc = returnExchangeException(
        const PostgrestException(message: '{"code":"WEIRD","message":"m"}'),
      );
      expect(exc.code, 'SYSTEM_ERROR');
    });

    test('maps raw boom PostgrestException to SYSTEM_ERROR', () {
      final exc = returnExchangeException(
        const PostgrestException(message: 'boom'),
      );
      expect(exc.code, 'SYSTEM_ERROR');
    });

    test('preserves NETWORK_ERROR', () {
      final exc = returnExchangeException(const AppException('NETWORK_ERROR'));
      expect(exc.code, 'NETWORK_ERROR');
    });

    test('maps FormatException to SYSTEM_ERROR', () {
      final exc = returnExchangeException(const FormatException('x'));
      expect(exc.code, 'SYSTEM_ERROR');
    });

    test('unwraps nested 2-layer JSON', () {
      final exc = returnExchangeException(
        const PostgrestException(message: '{"message":"{\\"code\\":\\"NOT_FOUND\\"}"}'),
      );
      expect(exc.code, 'NOT_FOUND');
    });
  });
}

