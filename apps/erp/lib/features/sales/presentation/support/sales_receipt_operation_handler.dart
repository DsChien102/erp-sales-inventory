import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../bloc/sales_order/sales_transaction_result_issue.dart';
import '../models/sales_receipt/sales_receipt_device_action.dart';
import '../models/sales_receipt/sales_receipt_operation_state.dart';
import 'sales_transaction_result_mapper.dart';

/// Shared lazy get/generate/print/share receipt operations (Group E + S19).
final class SalesReceiptOperationHandler {
  SalesReceiptOperationHandler({
    required this.salesOrderId,
    required ISalesModule salesModule,
    required IExecutionContext executionContext,
    required int Function() sourceVersion,
    required bool Function() hasSourceVersion,
    required String? Function() knownReceiptId,
    required void Function(String?) setKnownReceiptId,
    required SalesReceiptOperationState Function() readReceipt,
    required void Function(SalesReceiptOperationState) emitReceipt,
    required bool Function() isClosed,
    required int Function() currentGeneration,
  }) : _salesModule = salesModule,
       _executionContext = executionContext,
       _sourceVersion = sourceVersion,
       _hasSourceVersion = hasSourceVersion,
       _knownReceiptId = knownReceiptId,
       _setKnownReceiptId = setKnownReceiptId,
       _readReceipt = readReceipt,
       _emitReceipt = emitReceipt,
       _isClosed = isClosed,
       _currentGeneration = currentGeneration;

  final String salesOrderId;
  final ISalesModule _salesModule;
  final IExecutionContext _executionContext;
  final int Function() _sourceVersion;
  final bool Function() _hasSourceVersion;
  final String? Function() _knownReceiptId;
  final void Function(String?) _setKnownReceiptId;
  final SalesReceiptOperationState Function() _readReceipt;
  final void Function(SalesReceiptOperationState) _emitReceipt;
  final bool Function() _isClosed;
  final int Function() _currentGeneration;

  bool _receiptOperationInFlight = false;
  _ReceiptActivity? _pendingActivity;
  int _operationToken = 0;

  Future<void> ensureReceipt() async {
    if (_receiptOperationInFlight || _isClosed()) return;
    final current = _readReceipt();
    if (_pendingActivity != null && current.value != null) return;
    if (!_hasSourceVersion()) {
      _emitReceipt(
        SalesReceiptOperationState(
          status: SalesReceiptOperationStatus.error,
          value: current.value,
          issue: SalesTransactionResultIssue.contextInvalid,
        ),
      );
      return;
    }
    final generation = _currentGeneration();
    final token = ++_operationToken;
    _receiptOperationInFlight = true;
    _emitIfCurrent(
      generation,
      const SalesReceiptOperationState(status: SalesReceiptOperationStatus.generating),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final knownId = _knownReceiptId();
      final version = _sourceVersion();
      final receipt = knownId == null
          ? await _salesModule.executeCommandAsync<SalesReceiptDto>(
              GenerateSalesReceiptCommand(
                tenantId: tenantId,
                actorId: actorId,
                salesOrderId: salesOrderId,
                idempotencyKey: _generateIdempotencyKey(tenantId, version),
                correlationId: _executionContext.correlationId,
                expectedVersion: version,
              ),
            )
          : await _salesModule.executeQueryAsync<SalesReceiptDto>(
              GetSalesReceiptQuery(
                tenantId: tenantId,
                actorId: actorId,
                receiptId: knownId,
                expectedSourceVersion: version,
              ),
            );
      if (!_isCurrent(generation)) return;
      _setKnownReceiptId(receipt.receiptId);
      _emitIfCurrent(
        generation,
        SalesReceiptOperationState(status: SalesReceiptOperationStatus.ready, value: receipt),
      );
    } catch (error) {
      _emitIfCurrent(
        generation,
        SalesReceiptOperationState(
          status: SalesReceiptOperationStatus.error,
          value: _readReceipt().value,
          issue: SalesTransactionResultMapper.issueFor(error),
        ),
      );
    } finally {
      if (token == _operationToken) {
        _receiptOperationInFlight = false;
      }
    }
  }

  Future<void> printReceipt(SalesReceiptDeviceAction action) =>
      _performReceiptOperation(action: action, kind: _ReceiptActivityKind.print);

  Future<void> shareReceipt(SalesReceiptDeviceAction action) =>
      _performReceiptOperation(action: action, kind: _ReceiptActivityKind.share);

  /// Cancels in-flight/pending receipt work and resets operation state to idle.
  ///
  /// Callers that bump a request generation should invoke this so a later
  /// completion cannot overwrite the newer core/version.
  void invalidate() {
    _operationToken++;
    _pendingActivity = null;
    _receiptOperationInFlight = false;
    _emitReceipt(const SalesReceiptOperationState());
  }

  Future<void> _performReceiptOperation({
    required SalesReceiptDeviceAction action,
    required _ReceiptActivityKind kind,
  }) async {
    if (_receiptOperationInFlight || _isClosed()) return;

    final current = _readReceipt();
    if (current.status == SalesReceiptOperationStatus.activityWarning && _pendingActivity != null) {
      if (_pendingActivity!.kind == kind) {
        final generation = _currentGeneration();
        final token = ++_operationToken;
        _receiptOperationInFlight = true;
        await _recordReceiptActivity(_pendingActivity!, generation: generation);
        if (token == _operationToken) {
          _receiptOperationInFlight = false;
        }
      }
      return;
    }

    if (current.value == null) await ensureReceipt();
    final receipt = _readReceipt().value;
    if (receipt == null || _receiptOperationInFlight || _isClosed()) return;

    final generation = _currentGeneration();
    final token = ++_operationToken;
    _receiptOperationInFlight = true;
    final activeStatus = kind == _ReceiptActivityKind.print
        ? SalesReceiptOperationStatus.printing
        : SalesReceiptOperationStatus.sharing;
    _emitIfCurrent(
      generation,
      SalesReceiptOperationState(
        status: activeStatus,
        value: receipt,
        activityKind: kind.toPublicKind,
      ),
    );
    try {
      await action(receipt.document);
    } catch (error) {
      _emitIfCurrent(
        generation,
        SalesReceiptOperationState(
          status: SalesReceiptOperationStatus.error,
          value: receipt,
          issue: SalesTransactionResultMapper.issueFor(error),
          activityKind: kind.toPublicKind,
        ),
      );
      if (token == _operationToken) {
        _receiptOperationInFlight = false;
      }
      return;
    }

    if (!_isCurrent(generation)) {
      if (token == _operationToken) {
        _receiptOperationInFlight = false;
      }
      return;
    }

    _pendingActivity = _ReceiptActivity.create(kind: kind, receiptId: receipt.receiptId);
    await _recordReceiptActivity(_pendingActivity!, generation: generation);
    if (token == _operationToken) {
      _receiptOperationInFlight = false;
    }
  }

  Future<void> _recordReceiptActivity(
    _ReceiptActivity activity, {
    required int generation,
  }) async {
    final receipt = _readReceipt().value;
    if (receipt == null) return;
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final updatedReceipt = switch (activity.kind) {
        _ReceiptActivityKind.print => await _salesModule.executeCommandAsync<SalesReceiptDto>(
          RecordSalesReceiptPrintedCommand(
            id: activity.id,
            tenantId: tenantId,
            actorId: actorId,
            receiptId: activity.receiptId,
            idempotencyKey: activity.idempotencyKey,
            correlationId: _executionContext.correlationId,
          ),
        ),
        _ReceiptActivityKind.share => await _salesModule.executeCommandAsync<SalesReceiptDto>(
          RecordSalesReceiptSharedCommand(
            id: activity.id,
            tenantId: tenantId,
            actorId: actorId,
            receiptId: activity.receiptId,
            idempotencyKey: activity.idempotencyKey,
            correlationId: _executionContext.correlationId,
          ),
        ),
      };
      if (!_isCurrent(generation)) return;
      _pendingActivity = null;
      _emitIfCurrent(
        generation,
        SalesReceiptOperationState(
          status: SalesReceiptOperationStatus.ready,
          value: updatedReceipt,
          activityKind: null,
        ),
      );
    } catch (error) {
      _emitIfCurrent(
        generation,
        SalesReceiptOperationState(
          status: SalesReceiptOperationStatus.activityWarning,
          value: receipt,
          issue: SalesTransactionResultMapper.issueFor(error),
          activityKind: activity.kind.toPublicKind,
        ),
      );
    }
  }

  void _emitIfCurrent(int generation, SalesReceiptOperationState receipt) {
    if (!_isCurrent(generation)) return;
    _emitReceipt(receipt);
  }

  bool _isCurrent(int generation) => !_isClosed() && generation == _currentGeneration();

  String _generateIdempotencyKey(String tenantId, int version) =>
      'sales-receipt:$tenantId:$salesOrderId:v$version';
}

enum _ReceiptActivityKind { print, share }

extension on _ReceiptActivityKind {
  SalesReceiptActivityKind get toPublicKind => switch (this) {
    _ReceiptActivityKind.print => SalesReceiptActivityKind.print,
    _ReceiptActivityKind.share => SalesReceiptActivityKind.share,
  };
}

final class _ReceiptActivity {
  _ReceiptActivity._({
    required this.kind,
    required this.receiptId,
    required this.id,
    required this.idempotencyKey,
  });

  factory _ReceiptActivity.create({
    required _ReceiptActivityKind kind,
    required String receiptId,
  }) {
    final operationId = const Uuid().v4();
    return _ReceiptActivity._(
      kind: kind,
      receiptId: receiptId,
      id: operationId,
      idempotencyKey: 'sales-receipt:${kind.name}:$receiptId:$operationId',
    );
  }

  final _ReceiptActivityKind kind;
  final String receiptId;
  final String id;
  final String idempotencyKey;
}
