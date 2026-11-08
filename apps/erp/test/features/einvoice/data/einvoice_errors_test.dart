// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_einvoice_infrastructure/src/errors/einvoice_error_mapper.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('einvoice_errors', () {
    const commonCases = <String, String>{
      'NO_PERMISSION: einvoice.issue required': EInvoiceErrorCodes.noPermission,
      'IDEMPOTENCY_CONFLICT: payload differs for key k': EInvoiceErrorCodes.idempotencyConflict,
      'INVALID_STATUS: ALREADY_ISSUED': EInvoiceErrorCodes.invalidStatus,
      'STATE_CHANGED: connection version mismatch': EInvoiceErrorCodes.stateChanged,
      'TEMPLATE_NOT_AVAILABLE: x': EInvoiceErrorCodes.systemError,
      'boom': EInvoiceErrorCodes.systemError,
      'ISSUANCE_NOT_READY: provider not connected': EInvoiceErrorCodes.issuanceNotReady,
    };

    group('common cases with old mapEinvoiceRpcError parity', () {
      for (final entry in commonCases.entries) {
        test('maps "${entry.key}" -> ${entry.value}', () {
          final pgEx = PostgrestException(message: entry.key, code: 'P0001');

          // Old mapping
          final oldException = mapEinvoiceRpcError(RpcException(pgEx.toString()));
          expect(oldException.code, entry.value);

          // New mapping
          final appEx = AppException.from(pgEx);
          final mapped = einvoiceException(appEx);
          expect(mapped.code, entry.value);
          expect(mapped.serverMessage, entry.key);
        });
      }

      test('maps permission denied (code 42501) -> NO_PERMISSION', () {
        final pgEx = const PostgrestException(
          message: 'permission denied for function issue_invoice',
          code: '42501',
        );

        final oldException = mapEinvoiceRpcError(RpcException(pgEx.toString()));
        expect(oldException.code, EInvoiceErrorCodes.noPermission);

        final appEx = AppException.from(pgEx);
        final mapped = einvoiceException(appEx);
        expect(mapped.code, EInvoiceErrorCodes.noPermission);
        expect(mapped.serverMessage, pgEx.message);
      });
    });

    group('new (intentional changes: Q2, Q7)', () {
      test('// Q2: ISSUANCE_NOT_READY parses details.blockers accurately', () {
        const message = 'ISSUANCE_NOT_READY: {"details":{"blockers":["ORDER_FULLY_RETURNED"]}}';
        final pgEx = const PostgrestException(message: message, code: 'P0001');
        final appEx = AppException.from(pgEx);
        final mapped = einvoiceException(appEx);

        expect(mapped.code, EInvoiceErrorCodes.issuanceNotReady);
        expect(mapped.details?['blockers'], ['ORDER_FULLY_RETURNED']);
        expect(mapped.serverMessage, message);
      });

      test('// Q7: CONFIG_NOT_READY maps to CONFIG_NOT_READY code', () {
        const message = 'CONFIG_NOT_READY: auto issue requires readiness';
        final pgEx = const PostgrestException(message: message, code: 'P0001');
        final appEx = AppException.from(pgEx);
        final mapped = einvoiceException(appEx);

        expect(mapped.code, EInvoiceErrorCodes.configNotReady);
        expect(mapped.serverMessage, message);
      });

      test('// Q2: AppException NETWORK_ERROR is preserved', () {
        const appEx = AppException(EInvoiceErrorCodes.network);
        final mapped = einvoiceException(appEx);
        expect(mapped.code, EInvoiceErrorCodes.network);
      });

      test('FormatException and StateError map to SYSTEM_ERROR', () {
        final fEx = const FormatException('invalid format');
        final mappedFormat = einvoiceException(fEx);
        expect(mappedFormat.code, EInvoiceErrorCodes.systemError);
        expect(mappedFormat.cause, fEx);

        final sEx = StateError('bad state');
        final mappedState = einvoiceException(sEx);
        expect(mappedState.code, EInvoiceErrorCodes.systemError);
        expect(mappedState.cause, sEx);
      });

      test('AppException with other code is preserved', () {
        const appEx = AppException(
          EInvoiceErrorCodes.validationError,
          serverMessage: 'username is required',
        );
        final mapped = einvoiceException(appEx);
        expect(mapped.code, EInvoiceErrorCodes.validationError);
        expect(mapped.serverMessage, 'username is required');
      });
    });
  });
}

