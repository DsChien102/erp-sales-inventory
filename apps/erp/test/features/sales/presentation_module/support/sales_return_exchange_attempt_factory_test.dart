import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';

import '../../data/sales_post_sale_parity_expectations.dart';

void main() {
  ReturnExchangeLineInput returnedLine({
    String? reasonCode = 'damaged',
    String? conditionCode = 'opened',
    int quantityMicros = QuantityDto.scale,
  }) => ReturnExchangeLineInput(
    kind: ReturnExchangeLineKind.returnLine,
    productId: 'product-1',
    productUnitId: 'unit-1',
    quantity: QuantityDto(quantityMicros: quantityMicros),
    originalSalesOrderLineId: 'line-1',
    reasonCode: reasonCode,
    conditionCode: conditionCode,
  );

  test('return_exchange_hash_unchanged_start', () {
    final factory = SalesReturnExchangeAttemptFactory(
      newAttemptId: () => parityCommandId,
    );
    final attempt = factory.start(
      tenantId: parityTenantId,
      actorId: parityActorId,
      salesOrderId: parityOrderId,
      entrySource: ReturnExchangeEntrySource.standard,
      lines: sampleParityLines,
      expectedVersion: 7,
      correlationId: parityCorrelationId,
    );
    expect(attempt.payloadHash, expectedStartHash);
  });

  test('return_exchange_hash_unchanged_confirm', () {
    final factory = SalesReturnExchangeAttemptFactory(
      newAttemptId: () => parityCommandId,
    );
    final attempt = factory.confirm(
      tenantId: parityTenantId,
      actorId: parityActorId,
      returnExchangeId: parityReturnExchangeId,
      expectedVersion: 4,
      correlationId: parityCorrelationId,
      settledNowMinor: 100000,
      paymentMethod: SalesPaymentMethod.cash,
      paymentDueDate: DateTime(2026, 11, 20, 23, 30),
    );
    expect(attempt.payloadHash, expectedConfirmHash);
  });

  test('UUID becomes command id and return-exchange operation key', () {
    final factory = SalesReturnExchangeAttemptFactory(
      newAttemptId: () => '11111111-1111-4111-8111-111111111111',
    );

    final attempt = factory.start(
      tenantId: ' tenant-1 ',
      actorId: ' actor-1 ',
      salesOrderId: ' order-1 ',
      entrySource: ReturnExchangeEntrySource.standard,
      lines: [returnedLine()],
      expectedVersion: 7,
      correlationId: ' corr-1 ',
    );

    expect(attempt.request.commandId, '11111111-1111-4111-8111-111111111111');
    expect(
      attempt.request.idempotencyKey,
      'return-exchange:start:11111111-1111-4111-8111-111111111111',
    );
    expect(attempt.payloadHash, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(attempt.request.payloadHash, attempt.payloadHash);
    expect(attempt.request.correlationId, 'corr-1');
    expect(attempt.request.entrySource, ReturnExchangeEntrySource.standard);
    expect(attempt.request.lines.single.reasonCode, 'DAMAGED');
    expect(attempt.request.lines.single.conditionCode, 'OPENED');
    expect(
      attempt.canonicalPayloadJson,
      contains('"entrySource":"standard"'),
    );
    expect(attempt.canonicalPayloadJson, contains('"reasonCode":"DAMAGED"'));
  });

  test('equal payload gives equal hash; new attempt gives different key', () {
    final ids = ['attempt-1', 'attempt-2'].iterator;
    final factory = SalesReturnExchangeAttemptFactory(
      newAttemptId: () {
        ids.moveNext();
        return ids.current;
      },
    );

    final first = factory.confirm(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      returnExchangeId: 'return-1',
      expectedVersion: 4,
      correlationId: 'corr-1',
    );
    final second = factory.confirm(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      returnExchangeId: 'return-1',
      expectedVersion: 4,
      correlationId: 'corr-1',
    );

    expect(first.payloadHash, second.payloadHash);
    expect(first.request.idempotencyKey, isNot(second.request.idempotencyKey));
  });

  test('changed quantity/reason/condition/version changes hash', () {
    final factory = SalesReturnExchangeAttemptFactory(
      newAttemptId: () => 'attempt-1',
    );
    final base = factory.update(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      returnExchangeId: 'return-1',
      lines: [returnedLine()],
      expectedVersion: 3,
      correlationId: 'corr-1',
    );
    final qty = factory.update(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      returnExchangeId: 'return-1',
      lines: [returnedLine(quantityMicros: QuantityDto.scale * 2)],
      expectedVersion: 3,
      correlationId: 'corr-1',
    );
    final reason = factory.update(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      returnExchangeId: 'return-1',
      lines: [returnedLine(reasonCode: 'WRONG')],
      expectedVersion: 3,
      correlationId: 'corr-1',
    );
    final version = factory.update(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      returnExchangeId: 'return-1',
      lines: [returnedLine()],
      expectedVersion: 4,
      correlationId: 'corr-1',
    );

    expect(base.payloadHash, isNot(qty.payloadHash));
    expect(base.payloadHash, isNot(reason.payloadHash));
    expect(base.payloadHash, isNot(version.payloadHash));
  });

  test('confirm carries payment fields and hashes them into the payload', () {
    final factory = SalesReturnExchangeAttemptFactory(
      newAttemptId: () => 'attempt-1',
    );
    SalesReturnExchangeAttempt<ReturnExchangeConfirmRequest> confirm({
      int? settledNowMinor,
      SalesPaymentMethod method = SalesPaymentMethod.cash,
      DateTime? dueDate,
    }) => factory.confirm(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      returnExchangeId: 'return-1',
      expectedVersion: 4,
      correlationId: 'corr-1',
      settledNowMinor: settledNowMinor,
      paymentMethod: method,
      paymentDueDate: dueDate,
    );

    final full = confirm();
    final partial = confirm(
      settledNowMinor: 150000,
      method: SalesPaymentMethod.manualBankTransfer,
      dueDate: DateTime(2026, 7, 30),
    );

    expect(partial.request.settledNowMinor, 150000);
    expect(partial.request.paymentMethod, SalesPaymentMethod.manualBankTransfer);
    expect(partial.request.paymentDueDate, DateTime(2026, 7, 30));
    // Different payment inputs must produce a distinct idempotent payload.
    expect(full.payloadHash, isNot(partial.payloadHash));

    expect(
      () => confirm(settledNowMinor: -1),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTEXT_INVALID')),
    );
  });

  test('correlation is trimmed and never synthesized', () {
    final factory = SalesReturnExchangeAttemptFactory(
      newAttemptId: () => 'attempt-1',
    );
    expect(
      () => factory.discard(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        returnExchangeId: 'return-1',
        expectedVersion: 5,
        correlationId: '   ',
      ),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTEXT_INVALID')),
    );
  });

  test('returned line permits omitted temporary reason and condition policy', () {
    final factory = SalesReturnExchangeAttemptFactory(
      newAttemptId: () => 'attempt-1',
    );

    final attempt = factory.start(
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      salesOrderId: 'order-1',
      entrySource: ReturnExchangeEntrySource.standard,
      lines: [returnedLine(reasonCode: null, conditionCode: null)],
      expectedVersion: 1,
      correlationId: 'corr-1',
    );

    expect(attempt.request.lines.single.reasonCode, isNull);
    expect(attempt.request.lines.single.conditionCode, isNull);
    expect(attempt.canonicalPayloadJson, contains('"reasonCode":null'));
    expect(attempt.canonicalPayloadJson, contains('"conditionCode":null'));
  });
}
