import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';

import 'package:erp/features/sales/presentation/bloc/sales_order/sales_transaction_result_state.dart';
import 'package:erp/features/sales/presentation/support/sales_transaction_result_mapper.dart';

void main() {
  group('SalesTransactionResultMapper', () {
    test('maps contract errors to stable typed issues', () {
      expect(
        SalesTransactionResultMapper.issueFor(
          const SalesContractException('PROJECTION_PENDING'),
        ),
        SalesTransactionResultIssue.projectionPending,
      );
      expect(
        SalesTransactionResultMapper.issueFor(
          const SalesContractException('PERMISSION_DENIED'),
        ),
        SalesTransactionResultIssue.permissionDenied,
      );
      expect(
        SalesTransactionResultMapper.issueFor(
          const SalesContractException('NOT_FOUND'),
        ),
        SalesTransactionResultIssue.notFound,
      );
    });

    test('maps unknown transport failures without copying exception text', () {
      expect(
        SalesTransactionResultMapper.issueFor(const SocketException('private host details')),
        SalesTransactionResultIssue.transportFailure,
      );
    });
  });
}
