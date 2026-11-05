// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const stableCodes = [
    PricingErrorCodes.noPermission,
    PricingErrorCodes.notFound,
    PricingErrorCodes.validationError,
    PricingErrorCodes.duplicateActiveRule,
    PricingErrorCodes.belowFloorBlocked,
    PricingErrorCodes.referenceInvalid,
    PricingErrorCodes.idempotencyConflict,
    PricingErrorCodes.stateChanged,
    PricingErrorCodes.invalidStatus,
    PricingErrorCodes.systemError,
  ];

  const envelopeCases = <({String name, String message, String expectedCode})>[
    (
      name: 'DUPLICATE_ACTIVE_RULE with details',
      message:
          '{"code":"DUPLICATE_ACTIVE_RULE","message":"x","details":{"conflictingRuleId":"r1","reason":"overwriteRequired"}}',
      expectedCode: PricingErrorCodes.duplicateActiveRule,
    ),
    (
      name: 'OVERWRITE_REQUIRED (not in stable codes)',
      message: '{"code":"OVERWRITE_REQUIRED","message":"x","details":{}}',
      expectedCode: PricingErrorCodes.systemError,
    ),
    (
      name: 'IMPORT_MODE_MISMATCH (unknown code)',
      message: '{"code":"IMPORT_MODE_MISMATCH","message":"x","details":{}}',
      expectedCode: PricingErrorCodes.systemError,
    ),
    (
      name: 'non-JSON message',
      message: 'boom',
      expectedCode: PricingErrorCodes.systemError,
    ),
  ];

  group('new (pricingException)', () {
    for (final code in stableCodes) {
      test('preserves stable code $code from PostgrestException', () {
        final ex = pricingException(
          PostgrestException(
            message: '{"code":"$code","message":"msg","details":{"k":"v"}}',
          ),
        );
        expect(ex.code, code);
        expect(ex.serverMessage, 'msg');
        expect(ex.details, {'k': 'v'});
      });
    }

    for (final c in envelopeCases) {
      test('maps ${c.name} -> ${c.expectedCode}', () {
        final ex = pricingException(PostgrestException(message: c.message));
        expect(ex.code, c.expectedCode);
        if (c.expectedCode == PricingErrorCodes.duplicateActiveRule) {
          expect(ex.details?['conflictingRuleId'], 'r1');
          expect(ex.details?['reason'], 'overwriteRequired');
        }
      });
    }

    for (final c in const <({String message, String expectedCode})>[
      (
        message: 'permission denied: pricing.sales.preview',
        expectedCode: PricingErrorCodes.noPermission,
      ),
      (
        message: 'not authenticated',
        expectedCode: PricingErrorCodes.systemError,
      ),
      (
        message: 'PERMISSION_DENIED: x',
        expectedCode: PricingErrorCodes.noPermission,
      ),
      (
        message: 'RESOURCE_NOT_FOUND: x',
        expectedCode: PricingErrorCodes.notFound,
      ),
    ]) {
      test(
        'maps non-JSON PostgrestException("${c.message}") -> ${c.expectedCode}',
        () {
          final ex = pricingException(PostgrestException(message: c.message));
          expect(ex.code, c.expectedCode);
        },
      );
    }

    test('maps FormatException and StateError to SYSTEM_ERROR', () {
      final formatErr = const FormatException('x');
      final mappedFormat = pricingException(formatErr);
      expect(mappedFormat.code, PricingErrorCodes.systemError);
      expect(mappedFormat.cause, same(formatErr));

      final stateErr = StateError('x');
      final mappedState = pricingException(stateErr);
      expect(mappedState.code, PricingErrorCodes.systemError);
      expect(mappedState.cause, same(stateErr));
    });

    test('preserves AppException(VALIDATION_ERROR) details', () {
      const original = AppException(
        PricingErrorCodes.validationError,
        serverMessage: 'Invalid payload.',
        details: {
          'fieldErrors': {'rulePriceMinor': 'must_be_positive'},
        },
      );
      final mapped = pricingException(original);
      expect(mapped.code, PricingErrorCodes.validationError);
      expect(mapped.serverMessage, 'Invalid payload.');
      expect(mapped.details, {
        'fieldErrors': {'rulePriceMinor': 'must_be_positive'},
      });
    });

    test('maps AppException with unstable code to SYSTEM_ERROR', () {
      const original = AppException(PricingErrorCodes.overwriteRequired);
      final mapped = pricingException(original);
      expect(mapped.code, PricingErrorCodes.systemError);
      expect(mapped.cause, same(original));
    });
  });
}

