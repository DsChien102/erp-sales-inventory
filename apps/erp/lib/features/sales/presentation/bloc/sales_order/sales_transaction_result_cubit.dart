import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../models/sales_receipt/sales_receipt_device_action.dart';
import '../../support/sales_receipt_operation_handler.dart';
import '../../support/sales_transaction_result_mapper.dart';
import 'sales_transaction_result_state.dart';

/// Loads the S13 result view from authoritative read contracts only.
final class SalesTransactionResultCubit extends Cubit<SalesTransactionResultState> {
  SalesTransactionResultCubit({
    required this.idempotencyKey,
    required this.storeId,
    required this.salesOrderId,
    required ISalesModule salesModule,
    required IExecutionContext executionContext,
    this.knownReceiptId,
    this.recoveryBackoff = const <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(seconds: 1),
    ],
    Future<void> Function(Duration)? delay,
  }) : _salesModule = salesModule,
       _executionContext = executionContext,
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
  final ISalesModule _salesModule;
  final IExecutionContext _executionContext;
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

    late final String tenantId;
    late final String actorId;
    try {
      tenantId = await _executionContext.requireTenantId();
      actorId = await _executionContext.requireUserId();
    } catch (error) {
      _fail(generation, SalesTransactionResultMapper.issueFor(error));
      return;
    }
    if (!_isCurrent(generation)) return;

    final attempt = await _getAttempt(
      tenantId: tenantId,
      actorId: actorId,
    );
    if (!_isCurrent(generation)) return;

    if (attempt.value case final CheckoutResultDto value) {
      await _resolveAttempt(
        generation: generation,
        tenantId: tenantId,
        actorId: actorId,
        attempt: value,
      );
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
    await _recoverAttempt(generation: generation, tenantId: tenantId, actorId: actorId);
  }

  Future<void> retryLoad() => load();

  Future<_Read<CheckoutResultDto>> _getAttempt({
    required String tenantId,
    required String actorId,
  }) => _capture<CheckoutResultDto>(
    () => _salesModule.executeQueryAsync<CheckoutResultDto>(
      GetCheckoutResultQuery(
        tenantId: tenantId,
        actorId: actorId,
        idempotencyKey: idempotencyKey,
        storeId: storeId,
      ),
    ),
  );

  Future<void> _resolveAttempt({
    required int generation,
    required String tenantId,
    required String actorId,
    required CheckoutResultDto attempt,
  }) async {
    switch (attempt.status) {
      case CheckoutResultStatus.succeeded:
        await _loadSecondary(
          generation: generation,
          tenantId: tenantId,
          actorId: actorId,
          checkout: attempt,
        );
      case CheckoutResultStatus.processing ||
          CheckoutResultStatus.uncertain:
        await _recoverAttempt(generation: generation, tenantId: tenantId, actorId: actorId);
      case CheckoutResultStatus.blocked:
        _fail(generation, SalesTransactionResultIssue.checkoutBlocked);
      case CheckoutResultStatus.failed:
        _fail(generation, SalesTransactionResultIssue.checkoutFailed);
    }
  }

  Future<void> _recoverAttempt({
    required int generation,
    required String tenantId,
    required String actorId,
  }) async {
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

      final read = await _getAttempt(
        tenantId: tenantId,
        actorId: actorId,
      );
      if (!_isCurrent(generation)) return;
      if (read.value case final CheckoutResultDto value) {
        switch (value.status) {
          case CheckoutResultStatus.succeeded:
            await _loadSecondary(
              generation: generation,
              tenantId: tenantId,
              actorId: actorId,
              checkout: value,
            );
            return;
          case CheckoutResultStatus.blocked:
            _fail(generation, SalesTransactionResultIssue.checkoutBlocked);
            return;
          case CheckoutResultStatus.failed:
            _fail(generation, SalesTransactionResultIssue.checkoutFailed);
            return;
      case CheckoutResultStatus.processing ||
              CheckoutResultStatus.uncertain:
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
    required String tenantId,
    required String actorId,
    required CheckoutResultDto checkout,
  }) async {
    final orderFuture = _capture<SalesOrderResultDto>(
      () => _salesModule.executeQueryAsync<SalesOrderResultDto>(
        GetSalesOrderQuery(tenantId: tenantId, actorId: actorId, salesOrderId: salesOrderId),
      ),
    );
    final paymentFuture = _capture<SalesOrderPaymentSummaryDto>(
      () => _salesModule.executeQueryAsync<SalesOrderPaymentSummaryDto>(
        GetSalesOrderPaymentSummaryQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      ),
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
      error is! SalesContractException ||
      error.code == 'UNCERTAIN_RESULT' ||
      error.code == 'CHECKOUT_RESULT_NOT_FOUND';

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
