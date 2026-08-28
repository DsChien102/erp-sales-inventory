import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('EP-02 fake scenarios', () {
    test('issue_ok returns PROCESSING attempt', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.issueOk);
      final result = await module.executeCommandAsync(
        IssueInvoiceCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
          sourceVersion: 'sales-v:abc/1',
          idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
        ),
      );
      expect(result.status, IssuanceAttemptStatus.submitted);
    });

    test('issue_already_issued throws AlreadyIssuedException', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.issueAlreadyIssued);
      expect(
        () => module.executeCommandAsync(
          IssueInvoiceCommand(
            tenantId: 't1',
            actorId: 'a1',
            salesOrderId: 'so-1',
            sourceVersion: 'sales-v:abc/1',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
          ),
        ),
        throwsA(isA<AlreadyIssuedException>()),
      );
    });

    test('projection_processing shows processing state', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.projectionProcessing);
      final result = await module.executeQueryAsync(
        GetOrderInvoiceProjectionQuery(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so-1',
        ),
      );
      expect(result.issuanceDisplayState, IssuanceDisplayState.processing);
    });

    test('retry_while_reconciling throws OperationInProgressException', () async {
      final module = FakeEInvoiceModule(scenario: FakeEInvoiceScenario.retryWhileReconciling);
      expect(
        () => module.executeCommandAsync(
          RetryIssuanceCommand(
            tenantId: 't1',
            actorId: 'a1',
            salesOrderId: 'so-1',
            expectedOrderVersion: 1,
            idempotencyKey: 'k2',
          ),
        ),
        throwsA(isA<OperationInProgressException>()),
      );
    });
  });
}
