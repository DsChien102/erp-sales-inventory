// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/presentation/support/sales_record_payment_attempt_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';

void main() {
  group('SalesRecordPaymentAttemptFactory', () {
    test('same_content_same_hash', () {
      final ids = ['a1', 'a2'].iterator;
      final factory = SalesRecordPaymentAttemptFactory(
        newAttemptId: () {
          ids.moveNext();
          return ids.current;
        },
      );

      final attempt1 = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.cash,
        externalReference: null,
        correlationId: 'corr-1',
      );

      final attempt2 = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.cash,
        externalReference: null,
        correlationId: 'corr-1',
      );

      expect(attempt1.payloadHash, attempt2.payloadHash);
      expect(attempt1.request.idempotencyKey, 'sales-payment:a1');
      expect(attempt2.request.idempotencyKey, 'sales-payment:a2');
    });

    test('changed_amount_changes_hash', () {
      final factory = SalesRecordPaymentAttemptFactory(newAttemptId: () => 'attempt-1');

      final base = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.cash,
        correlationId: 'corr-1',
      );

      final changed = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 400000,
        method: SalesPaymentMethod.cash,
        correlationId: 'corr-1',
      );

      expect(changed.payloadHash, isNot(base.payloadHash));
    });

    test('changed_method_changes_hash', () {
      final factory = SalesRecordPaymentAttemptFactory(newAttemptId: () => 'attempt-1');

      final base = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.cash,
        correlationId: 'corr-1',
      );

      final changed = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.manualBankTransfer,
        correlationId: 'corr-1',
      );

      expect(changed.payloadHash, isNot(base.payloadHash));
    });

    test('changed_reference_changes_hash', () {
      final factory = SalesRecordPaymentAttemptFactory(newAttemptId: () => 'attempt-1');

      final base = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.manualBankTransfer,
        externalReference: 'REF-A',
        correlationId: 'corr-1',
      );

      final changed = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.manualBankTransfer,
        externalReference: 'REF-B',
        correlationId: 'corr-1',
      );

      expect(changed.payloadHash, isNot(base.payloadHash));
    });

    test('reference_trimmed_empty_is_null', () {
      final factory = SalesRecordPaymentAttemptFactory(newAttemptId: () => 'attempt-1');

      final trimmed = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.manualBankTransfer,
        externalReference: '   ',
        correlationId: 'corr-1',
      );

      final nullRef = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.manualBankTransfer,
        externalReference: null,
        correlationId: 'corr-1',
      );

      expect(trimmed.request.externalReference, isNull);
      expect(trimmed.payloadHash, nullRef.payloadHash);
    });

    test('amount_zero_throws_context_invalid', () {
      final factory = SalesRecordPaymentAttemptFactory(newAttemptId: () => 'attempt-1');

      expect(
        () => factory.create(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
          salesOrderId: 'order-1',
          amountMinor: 0,
          method: SalesPaymentMethod.cash,
          correlationId: 'corr-1',
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTEXT_INVALID')),
      );

      expect(
        () => factory.create(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
          salesOrderId: 'order-1',
          amountMinor: -1000,
          method: SalesPaymentMethod.cash,
          correlationId: 'corr-1',
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTEXT_INVALID')),
      );
    });

    test('hash_is_sha256_of_canonical_json', () {
      final factory = SalesRecordPaymentAttemptFactory(newAttemptId: () => 'attempt-1');

      final attempt = factory.create(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.cash,
        externalReference: null,
        correlationId: 'corr-1',
      );

      final expectedHash = sha256.convert(utf8.encode(attempt.canonicalPayloadJson)).toString();
      expect(attempt.payloadHash, expectedHash);
      expect(attempt.request.payloadHash, expectedHash);
    });
  });
}

