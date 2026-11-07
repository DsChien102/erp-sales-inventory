
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_payment_mutation_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  group('salesPaymentMutationException', () {
    test('keeps every Q6 stable code', () {
      const q6Codes = [
        'NO_PERMISSION',
        'DATA_SCOPE_DENIED',
        'CONTEXT_INVALID',
        'REFERENCE_UNAVAILABLE',
        'IDEMPOTENCY_CONFLICT',
        'ORDER_CANCELLED',
        'OVERPAYMENT_NOT_ALLOWED',
        'NETWORK_ERROR',
      ];

      for (final code in q6Codes) {
        final err = salesPaymentMutationException(AppException(code));
        expect(err.code, code);
      }
    });

    test('normalizes PERMISSION_DENIED to NO_PERMISSION', () {
      final err = salesPaymentMutationException(
        PostgrestException(message: '{"code":"PERMISSION_DENIED","message":"forbidden"}'),
      );
      expect(err.code, 'NO_PERMISSION');
    });

    test('maps unknown code WEIRD to SYSTEM_ERROR', () {
      final err = salesPaymentMutationException(
        PostgrestException(message: '{"code":"WEIRD","message":"weird"}'),
      );
      expect(err.code, 'SYSTEM_ERROR');
    });

    test('maps FormatException to SYSTEM_ERROR', () {
      final err = salesPaymentMutationException(const FormatException('malformed json'));
      expect(err.code, 'SYSTEM_ERROR');
    });

    test('nested NOT_FOUND maps to SYSTEM_ERROR because not in Q6 set', () {
      final err = salesPaymentMutationException(
        PostgrestException(
          message: '{"code":"OUTER","message":"{\\"code\\":\\"NOT_FOUND\\",\\"message\\":\\"x\\"}"}',
        ),
      );
      expect(err.code, 'SYSTEM_ERROR');
    });

    test('nested OVERPAYMENT_NOT_ALLOWED is unwrapped and kept', () {
      final err = salesPaymentMutationException(
        PostgrestException(
          message:
              '{"code":"OUTER","message":"{\\"code\\":\\"OVERPAYMENT_NOT_ALLOWED\\",\\"message\\":\\"exceeded\\"}"}',
        ),
      );
      expect(err.code, 'OVERPAYMENT_NOT_ALLOWED');
    });
  });
}

