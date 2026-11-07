// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_cancellation_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  group('salesCancellationException', () {
    test('extracts code and serverMessage from PostgrestException json', () {
      final exc = salesCancellationException(
        const PostgrestException(message: '{"code":"STALE_VERSION","message":"x"}'),
      );
      expect(exc.code, 'STALE_VERSION');
      expect(exc.serverMessage, 'x');
    });

    test('normalizes PERMISSION_DENIED to NO_PERMISSION', () {
      final exc = salesCancellationException(
        const PostgrestException(message: '{"code":"PERMISSION_DENIED","message":"denied"}'),
      );
      expect(exc.code, 'NO_PERMISSION');
    });

    for (final code in <String>{
      'NOT_FOUND',
      'NO_PERMISSION',
      'DATA_SCOPE_DENIED',
      'CANCELLATION_BLOCKED',
      'STALE_VERSION',
      'IDEMPOTENCY_CONFLICT',
      'IMPACT_PENDING',
      'DEPENDENCY_UNAVAILABLE',
      'IN_PROGRESS',
      'CONTEXT_INVALID',
      'FIELD_NOT_ALLOWED',
      'NETWORK_ERROR',
    }) {
      test('preserves $code', () {
        final exc = salesCancellationException(AppException(code));
        expect(exc.code, code);
      });
    }

    test('maps weird unknown code to SYSTEM_ERROR', () {
      final exc = salesCancellationException(
        const PostgrestException(message: '{"code":"WEIRD","message":"m"}'),
      );
      expect(exc.code, 'SYSTEM_ERROR');
    });

    test('maps raw boom PostgrestException to SYSTEM_ERROR', () {
      final exc = salesCancellationException(
        const PostgrestException(message: 'boom'),
      );
      expect(exc.code, 'SYSTEM_ERROR');
    });

    test('preserves NETWORK_ERROR', () {
      final exc = salesCancellationException(const AppException('NETWORK_ERROR'));
      expect(exc.code, 'NETWORK_ERROR');
    });

    test('maps FormatException to SYSTEM_ERROR', () {
      final exc = salesCancellationException(const FormatException('x'));
      expect(exc.code, 'SYSTEM_ERROR');
    });

    test('unwraps nested 2-layer JSON', () {
      final exc = salesCancellationException(
        const PostgrestException(message: '{"message":"{\\"code\\":\\"NOT_FOUND\\"}"}'),
      );
      expect(exc.code, 'NOT_FOUND');
    });
  });
}

