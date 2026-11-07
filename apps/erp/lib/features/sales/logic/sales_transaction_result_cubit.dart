import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_checkout_errors.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';

import 'package:erp/features/sales/presentation/models/sales_receipt/sales_receipt_device_action.dart';
import 'package:erp/features/sales/presentation/support/sales_receipt_operation_handler.dart';
import 'package:erp/features/sales/presentation/support/sales_transaction_result_mapper.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_state.dart';

/// Loads the S13 result view from authoritative read contracts only.
final class SalesTransactionResultCubit extends Cubit<SalesTransactionResultState> {
  SalesTransactionResultCubit({
    required this.idempotencyKey,
    required this.storeId,
    required this.salesOrderId,
    required SalesCheckoutRepository checkoutRepository,
    required SalesOrderRepository orderRepository,
    required SalesPaymentRepository paymentRepository,
    // Chỉ cho biên nhận (phiếu) — còn dùng module tới 8-A3.
    required ISalesModule salesModule,
    required IExecutionContext executionContext,
    this.knownReceiptId,
    this.recoveryBackoff = const <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(seconds: 1),
    ],
    Future<void> Function(Duration)? delay,
  }) : _checkoutRepository = checkoutRepository,
       _orderRepository = orderRepository,
       _paymentRepository = paymentRepository,
       _delay = delay ?? Future<void>.delayed,
       super(const SalesTransactionResultState()) {
    _receiptOps = SalesReceiptOperationHandler(
      salesOrderId: salesOrderId,
      salesModule: salesModule,
      executionContext: executionContext,
      sourceVersion: () => state.order?.order.version ?? state.checkout?.salesOrderVersion ?? 0,
      hasSourceVersion: () => state.order != null || state.checkout != null,
      knownReceiptId: () => knownReceiptId,
      setKnownReceiptId: (id) => knownReceiptId = id,
      readReceipt: () => state.receipt,
      emitReceipt: _emitReceipt,
      isClosed: () => isClosed,
      currentGeneration: () => _loadGeneration,
    );
  }

  final String idempotencyKey;
  final String storeId;
  final String salesOrderId;
  String? knownReceiptId;
  final SalesCheckoutRepository _checkoutRepository;
  final SalesOrderRepository _orderRepository;
  final SalesPaymentRepository _paymentRepository;
  final List<Duration> recoveryBackoff;
  final Future<void> Function(Duration) _delay;
  late final SalesReceiptOperationHandler _receiptOps;

  int _loadGeneration = 0;

  Future<void> ensureReceipt() => _receiptOps.ensureReceipt();

  Future<void> printReceipt(SalesReceiptDeviceAction action) => _receiptOps.printReceipt(action);

  Future<void> shareReceipt(SalesReceiptDeviceAction action) => _receiptOps.shareReceipt(action);

  void _emitReceipt(SalesReceiptOperationState receipt) {
    if (isClosed) return;
    emit(
      SalesTransactionResultState(
        status: state.status,
        result: state.result,
        checkout: state.checkout,
        order: state.order,
        payment: state.payment,
        issues: state.issues,
        receipt: receipt,
      ),
    );
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _emitIfCurrent(
      generation,
      const SalesTransactionResultState(status: SalesTransactionResultStatus.loading),
    );

    final attempt = await _getAttempt();
    if (!_isCurrent(generation)) return;

    if (attempt.value case final CheckoutResultDto value) {
      await _resolveAttempt(generation: generation, attempt: value);
      return;
    }

    if (attempt.error case final Object error) {
      if (!_canRecoverFrom(error)) {
        _fail(generation, SalesTransactionResultMapper.issueFor(error));
        return;
      }
    }

    // A lost/ambiguous response cannot prove checkout failed, so recover via
    // the idempotent status query within the configured bounded backoff.
    await _recoverAttempt(generation: generation);
  }

  Future<void> retryLoad() => load();

  Future<_Read<CheckoutResultDto>> _getAttempt() => _capture<CheckoutResultDto>(
    () => _checkoutRepository.getResult(storeId: storeId, idempotencyKey: idempotencyKey),
  );

  Future<void> _resolveAttempt({
    required int generation,
    required CheckoutResultDto attempt,
  }) async {
    switch (attempt.status) {
      case CheckoutResultStatus.succeeded:
        await _loadSecondary(generation: generation, checkout: attempt);
      case CheckoutResultStatus.processing || CheckoutResultStatus.uncertain:
        await _recoverAttempt(generation: generation);
      case CheckoutResultStatus.blocked:
        _fail(generation, SalesTransactionResultIssue.checkoutBlocked);
      case CheckoutResultStatus.failed:
        _fail(generation, SalesTransactionResultIssue.checkoutFailed);
    }
  }

  Future<void> _recoverAttempt({required int generation}) async {
    _emitIfCurrent(
      generation,
      const SalesTransactionResultState(
        status: SalesTransactionResultStatus.uncertain,
        issues: <SalesTransactionResultIssue>[SalesTransactionResultIssue.uncertainResult],
      ),
    );

    for (final interval in recoveryBackoff) {
      await _delay(interval);
      if (!_isCurrent(generation)) return;

      final read = await _getAttempt();
      if (!_isCurrent(generation)) return;
      if (read.value case final CheckoutResultDto value) {
        switch (value.status) {
          case CheckoutResultStatus.succeeded:
            await _loadSecondary(generation: generation, checkout: value);
            return;
          case CheckoutResultStatus.blocked:
            _fail(generation, SalesTransactionResultIssue.checkoutBlocked);
            return;
          case CheckoutResultStatus.failed:
            _fail(generation, SalesTransactionResultIssue.checkoutFailed);
            return;
          case CheckoutResultStatus.processing || CheckoutResultStatus.uncertain:
            continue;
        }
      }
      if (read.error case final Object error) {
        if (!_canRecoverFrom(error)) {
          _fail(generation, SalesTransactionResultMapper.issueFor(error));
          return;
        }
      }
    }

    _fail(generation, SalesTransactionResultIssue.uncertainResult);
  }

  Future<void> _loadSecondary({
    required int generation,
    required CheckoutResultDto checkout,
  }) async {
    final orderFuture = _capture<SalesOrderResultDto>(
      () => _orderRepository.get(salesOrderId: salesOrderId),
    );
    final paymentFuture = _capture<SalesOrderPaymentSummaryDto>(
      () => _paymentRepository.getSummary(salesOrderId: salesOrderId),
    );
    await Future.wait<void>([
      orderFuture.then<void>((_) {}),
      paymentFuture.then<void>((_) {}),
    ]);
    if (!_isCurrent(generation)) return;

    final orderRead = await orderFuture;
    final paymentRead = await paymentFuture;

    if (orderRead.error case final Object error) {
      _fail(generation, SalesTransactionResultMapper.issueFor(error));
      return;
    }
    final order = orderRead.value;
    if (order == null) {
      _fail(generation, SalesTransactionResultIssue.transportFailure);
      return;
    }
    final payment = paymentRead.value;
    final issues = <SalesTransactionResultIssue>[
      if (paymentRead.error case final Object error) SalesTransactionResultMapper.issueFor(error),
    ];

    if (issues.isEmpty) {
      _emitIfCurrent(
        generation,
        SalesTransactionResultState(
          status: SalesTransactionResultStatus.loaded,
          result: CheckoutResultViewDto(
            checkout: checkout,
            order: order,
            payment: payment!,
          ),
          checkout: checkout,
          order: order,
          payment: payment,
        ),
      );
      return;
    }

    _emitIfCurrent(
      generation,
      SalesTransactionResultState(
        status: SalesTransactionResultStatus.partial,
        checkout: checkout,
        order: order,
        payment: payment,
        issues: List<SalesTransactionResultIssue>.unmodifiable(issues),
      ),
    );
  }

  Future<_Read<T>> _capture<T>(Future<T> Function() operation) async {
    try {
      return _Read<T>.value(await operation());
    } catch (error) {
      return _Read<T>.error(error);
    }
  }

  bool _isCurrent(int generation) => !isClosed && generation == _loadGeneration;

  bool _canRecoverFrom(Object error) =>
      error is! AppException ||
      error.code == SalesCheckoutErrorCodes.uncertainResult ||
      error.code == SalesCheckoutErrorCodes.checkoutResultNotFound ||
      error.code == SalesCheckoutErrorCodes.networkError;

  void _emitIfCurrent(int generation, SalesTransactionResultState next) {
    if (_isCurrent(generation)) emit(next);
  }

  void _fail(int generation, SalesTransactionResultIssue issue) {
    _emitIfCurrent(
      generation,
      SalesTransactionResultState(
        status: SalesTransactionResultStatus.failure,
        issues: <SalesTransactionResultIssue>[issue],
      ),
    );
  }
}

final class _Read<T> {
  const _Read.value(this.value) : error = null;

  const _Read.error(this.error) : value = null;

  final T? value;
  final Object? error;
}
