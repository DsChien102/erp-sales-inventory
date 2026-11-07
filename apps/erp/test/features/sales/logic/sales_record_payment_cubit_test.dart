// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'package:erp/features/sales/logic/sales_record_payment_cubit.dart';
import 'package:erp/features/sales/logic/sales_record_payment_state.dart';
import 'package:erp/features/sales/presentation/support/i_sales_active_store_context.dart';
import 'package:erp/features/sales/presentation/support/sales_record_payment_attempt_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../support/fake_sales_payment_repository.dart';

final class _TestExecutionContext implements IExecutionContext {
  const _TestExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'actor-1';
}

final class _TestActiveStoreContext implements ISalesActiveStoreContext {
  const _TestActiveStoreContext();

  @override
  String? get activeStoreId => 'store-1';

  @override
  Future<String> requireActiveStoreId() async => 'store-1';
}

void main() {
  late FakeSalesPaymentRepository repo;
  late _TestExecutionContext executionContext;
  late _TestActiveStoreContext activeStoreContext;

  setUp(() {
    repo = FakeSalesPaymentRepository();
    repo.recordResult = const SalesRecordPaymentResult(
      transactionId: 'tx-1',
      outstandingMinor: 0,
      paymentStatus: 'paid',
      version: 2,
    );
    executionContext = const _TestExecutionContext();
    activeStoreContext = const _TestActiveStoreContext();
  });

  SalesRecordPaymentCubit buildCubit({
    int outstandingMinor = 600000,
    String salesOrderId = 'order-1',
    SalesRecordPaymentAttemptFactory? attemptFactory,
  }) {
    return SalesRecordPaymentCubit(
      repository: repo,
      executionContext: executionContext,
      activeStoreContext: activeStoreContext,
      salesOrderId: salesOrderId,
      outstandingMinor: outstandingMinor,
      attemptFactory: attemptFactory,
    );
  }

  group('SalesRecordPaymentCubit', () {
    test('default_amount_is_outstanding_and_method_cash', () {
      final cubit = buildCubit(outstandingMinor: 600000);
      expect(cubit.state.status, SalesRecordPaymentStatus.editing);
      expect(cubit.state.amountMinor, 600000);
      expect(cubit.state.method, SalesPaymentMethod.cash);
      expect(cubit.state.fieldError, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.canRetry, isFalse);
    });

    test('zero_amount_field_error', () async {
      final cubit = buildCubit();

      cubit.setAmountMinor(0);
      await cubit.submit();
      expect(cubit.state.fieldError, 'Số tiền phải lớn hơn 0.');
      expect(repo.recordCalls, isEmpty);

      cubit.setAmountMinor(null);
      await cubit.submit();
      expect(cubit.state.fieldError, 'Số tiền phải lớn hơn 0.');
      expect(repo.recordCalls, isEmpty);
    });

    test('over_outstanding_field_error', () async {
      final cubit = buildCubit(outstandingMinor: 600000);

      cubit.setAmountMinor(600001);
      await cubit.submit();
      expect(cubit.state.fieldError, 'Số tiền vượt quá số còn phải thu.');
      expect(repo.recordCalls, isEmpty);
    });

    test('submit_success (AC-01)', () async {
      final cubit = buildCubit(outstandingMinor: 600000);

      await cubit.submit();

      expect(cubit.state.status, SalesRecordPaymentStatus.succeeded);
      expect(cubit.state.result, isNotNull);
      expect(cubit.state.result!.transactionId, 'tx-1');
      expect(repo.recordCalls.length, 1);
      expect(repo.recordCalls.first.amountMinor, 600000);
      expect(repo.recordCalls.first.method, SalesPaymentMethod.cash);
      expect(repo.recordCalls.first.salesOrderId, 'order-1');
    });

    test('partial_success (AC-02)', () async {
      final cubit = buildCubit(outstandingMinor: 600000);
      cubit.setAmountMinor(200000);

      await cubit.submit();

      expect(cubit.state.status, SalesRecordPaymentStatus.succeeded);
      expect(repo.recordCalls.length, 1);
      expect(repo.recordCalls.first.amountMinor, 200000);
    });

    test('network_error_retry_reuses_key (AC-03)', () async {
      final attemptIds = ['attempt-1', 'attempt-2'].iterator;
      final attemptFactory = SalesRecordPaymentAttemptFactory(
        newAttemptId: () {
          attemptIds.moveNext();
          return attemptIds.current;
        },
      );
      final cubit = buildCubit(attemptFactory: attemptFactory);

      repo.recordErrors.add(const AppException('NETWORK_ERROR'));
      await cubit.submit();

      expect(cubit.state.status, SalesRecordPaymentStatus.failure);
      expect(cubit.state.canRetry, isTrue);
      expect(cubit.state.errorMessage, 'Không thể ghi nhận thanh toán. Vui lòng thử lại.');
      expect(repo.recordCalls.length, 1);
      final firstKey = repo.recordCalls[0].idempotencyKey;
      expect(firstKey, 'sales-payment:attempt-1');

      // Retry without changing payload
      await cubit.submit();

      expect(cubit.state.status, SalesRecordPaymentStatus.succeeded);
      expect(repo.recordCalls.length, 2);
      final secondKey = repo.recordCalls[1].idempotencyKey;
      expect(secondKey, firstKey);
    });

    test('changed_amount_creates_new_attempt', () async {
      final attemptIds = ['attempt-1', 'attempt-2'].iterator;
      final attemptFactory = SalesRecordPaymentAttemptFactory(
        newAttemptId: () {
          attemptIds.moveNext();
          return attemptIds.current;
        },
      );
      final cubit = buildCubit(attemptFactory: attemptFactory);

      repo.recordErrors.add(const AppException('NETWORK_ERROR'));
      await cubit.submit();
      expect(cubit.state.canRetry, isTrue);

      // Change amount
      cubit.setAmountMinor(400000);
      await cubit.submit();

      expect(repo.recordCalls.length, 2);
      expect(repo.recordCalls[0].idempotencyKey, 'sales-payment:attempt-1');
      expect(repo.recordCalls[1].idempotencyKey, 'sales-payment:attempt-2');
      expect(repo.recordCalls[1].amountMinor, 400000);
    });

    test('double_submit_ignored', () async {
      final cubit = buildCubit();

      final future1 = cubit.submit();
      final future2 = cubit.submit();
      await Future.wait<void>([future1, future2]);

      expect(repo.recordCalls.length, 1);
    });

    group('error message mapping table 4.3', () {
      final cases = [
        ('OVERPAYMENT_NOT_ALLOWED', 'Số tiền vượt quá số còn phải thu.', false),
        ('ORDER_CANCELLED', 'Đơn đã hủy, không thể thu thêm.', false),
        ('IDEMPOTENCY_CONFLICT', 'Yêu cầu bị xung đột', true),
        ('NO_PERMISSION', 'Bạn không có quyền thực hiện thao tác này.', false),
        ('DATA_SCOPE_DENIED', 'Cửa hàng hiện tại không còn khả dụng.', false),
        ('REFERENCE_UNAVAILABLE', 'Đơn hàng không tồn tại hoặc đã bị xóa.', false),
        ('CONTEXT_INVALID', 'Dữ liệu không hợp lệ.', false),
        ('NETWORK_ERROR', 'Không thể ghi nhận thanh toán. Vui lòng thử lại.', true),
        ('SYSTEM_ERROR', 'Không thể ghi nhận thanh toán. Vui lòng thử lại.', true),
        ('OTHER_WEIRD_CODE', 'Không thể ghi nhận thanh toán. Vui lòng thử lại.', true),
      ];

      for (final (code, expectedMsg, expectedCanRetry) in cases) {
        test('maps $code', () async {
          final cubit = buildCubit();
          repo.recordErrors.add(AppException(code));

          await cubit.submit();

          expect(cubit.state.status, SalesRecordPaymentStatus.failure);
          expect(cubit.state.errorMessage, expectedMsg);
          expect(cubit.state.canRetry, expectedCanRetry);
        });
      }
    });

    test('transfer_sends_trimmed_reference', () async {
      final cubit = buildCubit();
      cubit.setMethod(SalesPaymentMethod.manualBankTransfer);
      cubit.setExternalReference('  REF123456  ');

      await cubit.submit();

      expect(repo.recordCalls.length, 1);
      expect(repo.recordCalls.first.method, SalesPaymentMethod.manualBankTransfer);
      expect(repo.recordCalls.first.externalReference, 'REF123456');
    });

    test('cash_ignores_reference', () async {
      final cubit = buildCubit();
      cubit.setMethod(SalesPaymentMethod.cash);
      cubit.setExternalReference('REF123456');

      await cubit.submit();

      expect(repo.recordCalls.length, 1);
      expect(repo.recordCalls.first.method, SalesPaymentMethod.cash);
      expect(repo.recordCalls.first.externalReference, isNull);
    });

    test('edit_after_network_error_resets_retry', () async {
      repo.recordErrors.add(const AppException('NETWORK_ERROR'));
      final cubit = buildCubit();

      await cubit.submit();
      expect(cubit.state.status, SalesRecordPaymentStatus.failure);
      expect(cubit.state.canRetry, isTrue);

      cubit.setAmountMinor(500000);
      expect(cubit.state.status, SalesRecordPaymentStatus.editing);
      expect(cubit.state.canRetry, isFalse);
    });
  });
}
