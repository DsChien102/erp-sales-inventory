import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_issue.dart';
import 'package:erp/features/sales/presentation/models/sales_receipt/sales_receipt_device_action.dart';
import 'package:erp/features/sales/presentation/models/sales_receipt/sales_receipt_operation_state.dart';
import 'package:erp/features/sales/presentation/support/sales_transaction_result_mapper.dart';
import 'package:uuid/uuid.dart';

/// Shared lazy get/generate/print/share receipt operations (Group E + S19).
final class SalesReceiptOperationHandler {
  SalesReceiptOperationHandler({
    required this.salesOrderId,
    required SalesReceiptRepository repository,
    required int Function() sourceVersion,
    required bool Function() hasSourceVersion,
    required String? Function() knownReceiptId,
    required void Function(String?) setKnownReceiptId,
    required SalesReceiptOperationState Function() readReceipt,
    required void Function(SalesReceiptOperationState) emitReceipt,
    required bool Function() isClosed,
    required int Function() currentGeneration,
  }) : _repository = repository,
       _sourceVersion = sourceVersion,
       _hasSourceVersion = hasSourceVersion,
       _knownReceiptId = knownReceiptId,
       _setKnownReceiptId = setKnownReceiptId,
       _readReceipt = readReceipt,
       _emitReceipt = emitReceipt,
       _isClosed = isClosed,
       _currentGeneration = currentGeneration;

  final String salesOrderId;
  final SalesReceiptRepository _repository;
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
      final knownId = _knownReceiptId();
      final version = _sourceVersion();
      final receipt = knownId == null
          ? await _repository.generate(
              salesOrderId: salesOrderId,
              expectedVersion: version,
            )
          : await _repository.get(
              receiptId: knownId,
              expectedSourceVersion: version,
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
      final updatedReceipt = switch (activity.kind) {
        _ReceiptActivityKind.print => await _repository.recordPrinted(
          receiptId: activity.receiptId,
          commandId: activity.id,
          idempotencyKey: activity.idempotencyKey,
        ),
        _ReceiptActivityKind.share => await _repository.recordShared(
          receiptId: activity.receiptId,
          commandId: activity.id,
          idempotencyKey: activity.idempotencyKey,
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
