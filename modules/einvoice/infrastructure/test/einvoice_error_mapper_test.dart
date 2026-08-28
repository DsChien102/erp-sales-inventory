import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/errors/einvoice_error_mapper.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('mapEinvoiceRpcError', () {
    test('maps S2 error codes to corresponding EInvoiceBlockedException', () {
      final s2Codes = [
        EInvoiceBlockedCodes.issuanceNotReady,
        EInvoiceBlockedCodes.buyerDataIncomplete,
        EInvoiceBlockedCodes.buyerTaxCodeRequired,
        EInvoiceBlockedCodes.orderNotCompleted,
        EInvoiceBlockedCodes.alreadyIssued,
        EInvoiceBlockedCodes.operationInProgress,
        EInvoiceBlockedCodes.resultUndetermined,
        EInvoiceBlockedCodes.documentUnavailable,
        EInvoiceBlockedCodes.deliveryNotSupported,
      ];

      for (final code in s2Codes) {
        final rpcException = RpcException(
          'RPC failed with error: $code - details',
        );
        final blockedException = mapEinvoiceRpcError(rpcException);

        expect(
          blockedException.code,
          equals(code),
          reason:
              'Expected $code to map to EInvoiceBlockedException with code $code',
        );
        expect(blockedException.message, equals(rpcException.message));
      }
    });

    test('maps legacy/existing error codes correctly', () {
      final existingCodes = [
        EInvoiceBlockedCodes.noPermission,
        EInvoiceBlockedCodes.notFound,
        EInvoiceBlockedCodes.validationError,
        EInvoiceBlockedCodes.invalidStatus,
        EInvoiceBlockedCodes.stateChanged,
        EInvoiceBlockedCodes.providerNotConnected,
        EInvoiceBlockedCodes.providerAuthFailed,
        EInvoiceBlockedCodes.providerUnavailable,
        EInvoiceBlockedCodes.configNotReady,
      ];

      for (final code in existingCodes) {
        final rpcException = RpcException('Error: $code occurred');
        final blockedException = mapEinvoiceRpcError(rpcException);

        expect(blockedException.code, equals(code));
        expect(blockedException.message, equals(rpcException.message));
      }
    });

    test('maps case-insensitively for code matching', () {
      final rpcException = RpcException('error: buyer_tax_code_required');
      final blockedException = mapEinvoiceRpcError(rpcException);

      expect(
        blockedException.code,
        equals(EInvoiceBlockedCodes.buyerTaxCodeRequired),
      );
    });

    test('maps permission denied text to noPermission', () {
      final rpcException = RpcException('Postgres permission denied for table');
      final blockedException = mapEinvoiceRpcError(rpcException);

      expect(blockedException.code, equals(EInvoiceBlockedCodes.noPermission));
    });

    test('falls back to systemError for unknown error messages', () {
      final rpcException = RpcException(
        'Unexpected database connection timeout',
      );
      final blockedException = mapEinvoiceRpcError(rpcException);

      expect(blockedException.code, equals(EInvoiceBlockedCodes.systemError));
      expect(blockedException.message, equals(rpcException.message));
    });

    test('maps IDEMPOTENCY_CONFLICT to idempotencyConflict code', () {
      final rpcException = RpcException(
        'IDEMPOTENCY_CONFLICT: same idempotency key with different business intent',
      );
      final blockedException = mapEinvoiceRpcError(rpcException);

      expect(
        blockedException.code,
        equals(EInvoiceBlockedCodes.idempotencyConflict),
      );
    });

    test(
      'maps ISSUANCE_NOT_READY to IssuanceNotReadyException with blockers',
      () {
        final rpcException = RpcException(
          'ISSUANCE_NOT_READY: {"details":{"blockers":["SOURCE_SNAPSHOT_UNAVAILABLE","BUYER_SOURCE_UNAVAILABLE"]}}',
        );
        final blockedException = mapEinvoiceRpcError(rpcException);

        expect(blockedException, isA<IssuanceNotReadyException>());
        expect(
          (blockedException as IssuanceNotReadyException).blockers,
          equals(['SOURCE_SNAPSHOT_UNAVAILABLE', 'BUYER_SOURCE_UNAVAILABLE']),
        );
      },
    );
  });
}
