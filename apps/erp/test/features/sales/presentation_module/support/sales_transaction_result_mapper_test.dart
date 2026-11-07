import 'dart:io';

import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:erp/features/sales/logic/sales_transaction_result_state.dart';
import 'package:erp/features/sales/presentation/support/sales_transaction_result_mapper.dart';

void main() {
  group('SalesTransactionResultMapper', () {
    const appCases = <String, SalesTransactionResultIssue>{
      'UNCERTAIN_RESULT': SalesTransactionResultIssue.uncertainResult,
      'CHECKOUT_BLOCKED': SalesTransactionResultIssue.checkoutBlocked,
      'NOT_FOUND': SalesTransactionResultIssue.notFound,
      'NO_PERMISSION': SalesTransactionResultIssue.permissionDenied,
      'DATA_SCOPE_DENIED': SalesTransactionResultIssue.permissionDenied,
      'PROJECTION_PENDING': SalesTransactionResultIssue.projectionPending,
      'STALE_VERSION': SalesTransactionResultIssue.staleVersion,
      'IDEMPOTENCY_CONFLICT': SalesTransactionResultIssue.idempotencyConflict,
      'CONTEXT_INVALID': SalesTransactionResultIssue.contextInvalid,
      'DEPENDENCY_UNAVAILABLE': SalesTransactionResultIssue.dependencyUnavailable,
      'NETWORK_ERROR': SalesTransactionResultIssue.transportFailure,
      'SYSTEM_ERROR': SalesTransactionResultIssue.transportFailure,
    };
    for (final entry in appCases.entries) {
      test('issue_for_app_exception_${entry.key}', () {
        expect(SalesTransactionResultMapper.issueFor(AppException(entry.key)), entry.value);
      });
    }

    test('maps unknown transport failures without copying exception text', () {
      expect(
        SalesTransactionResultMapper.issueFor(const SocketException('private host details')),
        SalesTransactionResultIssue.transportFailure,
      );
    });
  });
}
