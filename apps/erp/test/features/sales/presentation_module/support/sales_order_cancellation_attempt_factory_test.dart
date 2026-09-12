import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  test('builds canonical command, key and hash from context and versions', () {
    final factory = SalesOrderCancellationAttemptFactory(
      newAttemptId: () => '11111111-1111-4111-8111-111111111111',
    );

    final attempt = factory.create(
      tenantId: ' tenant-1 ',
      actorId: ' actor-1 ',
      salesOrderId: ' order-1 ',
      expectedOrderVersion: 7,
      expectedSettlementVersion: 3,
      reasonText: ' Khách nhập trùng đơn ',
      correlationId: ' corr-1 ',
    );

    expect(attempt.command.id, '11111111-1111-4111-8111-111111111111');
    expect(
      attempt.command.idempotencyKey,
      'sales-order-cancellation:11111111-1111-4111-8111-111111111111',
    );
    expect(attempt.command.tenantId, 'tenant-1');
    expect(attempt.command.actorId, 'actor-1');
    expect(attempt.command.salesOrderId, 'order-1');
    expect(attempt.command.expectedVersion, 7);
    expect(attempt.command.expectedSettlementVersion, 3);
    expect(attempt.command.reason.reasonText, 'Khách nhập trùng đơn');
    expect(attempt.command.correlationId, 'corr-1');
    expect(attempt.payloadHash, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(attempt.command.payloadHash, attempt.payloadHash);
    expect(
      attempt.canonicalPayloadJson,
      '{"expectedOrderVersion":7,"expectedSettlementVersion":3,'
      '"reasonText":"Khách nhập trùng đơn",'
      '"salesOrderId":"order-1","tenantId":"tenant-1"}',
    );
  });

  test('blank note canonicalizes to empty string and equal payloads share hash', () {
    final ids = ['attempt-1', 'attempt-2'].iterator;
    final factory = SalesOrderCancellationAttemptFactory(
      newAttemptId: () {
        ids.moveNext();
        return ids.current;
      },
    );

    final blank = factory.create(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      salesOrderId: 'order-1',
      expectedOrderVersion: 7,
      expectedSettlementVersion: 3,
      reasonText: '   ',
      correlationId: 'corr-1',
    );
    final nullNote = factory.create(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      salesOrderId: 'order-1',
      expectedOrderVersion: 7,
      expectedSettlementVersion: 3,
      reasonText: null,
      correlationId: 'corr-1',
    );

    expect(blank.command.reason.reasonText, isEmpty);
    expect(blank.payloadHash, nullNote.payloadHash);
    // Distinct attempts get distinct idempotency keys even for equal payloads.
    expect(blank.command.idempotencyKey, isNot(nullNote.command.idempotencyKey));
  });

  test('changing note or either version changes the hash', () {
    final factory = SalesOrderCancellationAttemptFactory(
      newAttemptId: () => 'attempt-x',
    );
    SalesOrderCancellationAttempt make({
      String? reasonText = 'note',
      int orderVersion = 7,
      int settlementVersion = 3,
    }) => factory.create(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      salesOrderId: 'order-1',
      expectedOrderVersion: orderVersion,
      expectedSettlementVersion: settlementVersion,
      reasonText: reasonText,
      correlationId: 'corr-1',
    );

    final base = make();
    expect(make(reasonText: 'other note').payloadHash, isNot(base.payloadHash));
    expect(make(orderVersion: 8).payloadHash, isNot(base.payloadHash));
    expect(make(settlementVersion: 4).payloadHash, isNot(base.payloadHash));
  });

  test('rejects blank context or non-positive versions before dispatch', () {
    final factory = SalesOrderCancellationAttemptFactory(
      newAttemptId: () => 'attempt-x',
    );
    SalesOrderCancellationAttempt call({
      String tenantId = 'tenant-1',
      String correlationId = 'corr-1',
      int orderVersion = 7,
      int settlementVersion = 3,
    }) => factory.create(
      tenantId: tenantId,
      actorId: 'actor-1',
      salesOrderId: 'order-1',
      expectedOrderVersion: orderVersion,
      expectedSettlementVersion: settlementVersion,
      reasonText: 'note',
      correlationId: correlationId,
    );

    expect(() => call(tenantId: '  '), throwsA(isA<SalesContractException>()));
    expect(() => call(correlationId: ''), throwsA(isA<SalesContractException>()));
    expect(() => call(orderVersion: 0), throwsA(isA<SalesContractException>()));
    expect(() => call(settlementVersion: 0), throwsA(isA<SalesContractException>()));
  });
}
