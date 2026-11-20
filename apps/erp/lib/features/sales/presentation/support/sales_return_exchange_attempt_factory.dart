import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:uuid/uuid.dart';
import 'package:erp/features/sales/data/models.dart';

enum SalesReturnExchangeOperation { start, update, discard, confirm }

/// Immutable return/exchange mutation attempt.
///
/// Retrying the same payload must reuse command id / idempotency key / hash.
/// Input or authoritative version changes invalidate the attempt.
final class SalesReturnExchangeAttempt<TRequest> {
  const SalesReturnExchangeAttempt({
    required this.operation,
    required this.request,
    required this.canonicalPayloadJson,
    required this.payloadHash,
  });

  final SalesReturnExchangeOperation operation;
  final TRequest request;
  final String canonicalPayloadJson;
  final String payloadHash;
}

final class SalesReturnExchangeAttemptFactory {
  SalesReturnExchangeAttemptFactory({String Function()? newAttemptId})
    : _newAttemptId = newAttemptId ?? const Uuid().v4;

  final String Function() _newAttemptId;

  SalesReturnExchangeAttempt<ReturnExchangeStartRequest> start({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required ReturnExchangeEntrySource entrySource,
    required List<ReturnExchangeLineInput> lines,
    required int expectedVersion,
    required String correlationId,
  }) {
    final context = _requireContext(
      tenantId: tenantId,
      actorId: actorId,
      correlationId: correlationId,
    );
    final trimmedSalesOrderId = salesOrderId.trim();
    if (trimmedSalesOrderId.isEmpty || expectedVersion <= 0) {
      throw const AppException('CONTEXT_INVALID');
    }
    final normalizedLines = _normalizeLines(lines);
    final payload = <String, Object?>{
      'entrySource': _entrySourceWire(entrySource),
      'expectedVersion': expectedVersion,
      'lines': normalizedLines,
      'salesOrderId': trimmedSalesOrderId,
      'tenantId': context.tenantId,
    };
    final built = _build(operation: SalesReturnExchangeOperation.start, payload: payload);
    return SalesReturnExchangeAttempt<ReturnExchangeStartRequest>(
      operation: SalesReturnExchangeOperation.start,
      request: ReturnExchangeStartRequest(
        commandId: built.attemptId,
        salesOrderId: trimmedSalesOrderId,
        entrySource: entrySource,
        lines: _toLineInputs(normalizedLines),
        idempotencyKey: built.idempotencyKey,
        payloadHash: built.payloadHash,
        correlationId: context.correlationId,
        expectedVersion: expectedVersion,
      ),
      canonicalPayloadJson: built.canonicalJson,
      payloadHash: built.payloadHash,
    );
  }

  SalesReturnExchangeAttempt<ReturnExchangeUpdateRequest> update({
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
    required List<ReturnExchangeLineInput> lines,
    required int expectedVersion,
    required String correlationId,
  }) {
    final context = _requireContext(
      tenantId: tenantId,
      actorId: actorId,
      correlationId: correlationId,
    );
    final trimmedReturnExchangeId = returnExchangeId.trim();
    if (trimmedReturnExchangeId.isEmpty || expectedVersion <= 0) {
      throw const AppException('CONTEXT_INVALID');
    }
    final normalizedLines = _normalizeLines(lines);
    final payload = <String, Object?>{
      'expectedVersion': expectedVersion,
      'lines': normalizedLines,
      'returnExchangeId': trimmedReturnExchangeId,
      'tenantId': context.tenantId,
    };
    final built = _build(operation: SalesReturnExchangeOperation.update, payload: payload);
    return SalesReturnExchangeAttempt<ReturnExchangeUpdateRequest>(
      operation: SalesReturnExchangeOperation.update,
      request: ReturnExchangeUpdateRequest(
        commandId: built.attemptId,
        returnExchangeId: trimmedReturnExchangeId,
        lines: _toLineInputs(normalizedLines),
        idempotencyKey: built.idempotencyKey,
        payloadHash: built.payloadHash,
        correlationId: context.correlationId,
        expectedVersion: expectedVersion,
      ),
      canonicalPayloadJson: built.canonicalJson,
      payloadHash: built.payloadHash,
    );
  }

  SalesReturnExchangeAttempt<ReturnExchangeMutationRequest> discard({
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
    required String correlationId,
    int? expectedVersion,
  }) {
    final context = _requireContext(
      tenantId: tenantId,
      actorId: actorId,
      correlationId: correlationId,
    );
    final trimmedReturnExchangeId = returnExchangeId.trim();
    if (trimmedReturnExchangeId.isEmpty) {
      throw const AppException('CONTEXT_INVALID');
    }
    if (expectedVersion != null && expectedVersion <= 0) {
      throw const AppException('CONTEXT_INVALID');
    }
    final payload = <String, Object?>{
      'expectedVersion': expectedVersion,
      'returnExchangeId': trimmedReturnExchangeId,
      'tenantId': context.tenantId,
    };
    final built = _build(operation: SalesReturnExchangeOperation.discard, payload: payload);
    return SalesReturnExchangeAttempt<ReturnExchangeMutationRequest>(
      operation: SalesReturnExchangeOperation.discard,
      request: ReturnExchangeMutationRequest(
        commandId: built.attemptId,
        returnExchangeId: trimmedReturnExchangeId,
        idempotencyKey: built.idempotencyKey,
        payloadHash: built.payloadHash,
        correlationId: context.correlationId,
        expectedVersion: expectedVersion,
      ),
      canonicalPayloadJson: built.canonicalJson,
      payloadHash: built.payloadHash,
    );
  }

  SalesReturnExchangeAttempt<ReturnExchangeConfirmRequest> confirm({
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
    required int expectedVersion,
    required String correlationId,
    int? settledNowMinor,
    SalesPaymentMethod paymentMethod = SalesPaymentMethod.cash,
    DateTime? paymentDueDate,
    List<String> offsetTargetOrderIds = const [],
  }) {
    final context = _requireContext(
      tenantId: tenantId,
      actorId: actorId,
      correlationId: correlationId,
    );
    final trimmedReturnExchangeId = returnExchangeId.trim();
    if (trimmedReturnExchangeId.isEmpty || expectedVersion <= 0) {
      throw const AppException('CONTEXT_INVALID');
    }
    if (settledNowMinor != null && settledNowMinor < 0) {
      throw const AppException('CONTEXT_INVALID');
    }
    // Payment inputs are part of the hashed payload so a different settle
    // amount / method / due date is a distinct idempotent attempt.
    final dueDate = paymentDueDate == null
        ? null
        : DateTime(paymentDueDate.year, paymentDueDate.month, paymentDueDate.day).toIso8601String();
    final payload = <String, Object?>{
      'expectedVersion': expectedVersion,
      'returnExchangeId': trimmedReturnExchangeId,
      'tenantId': context.tenantId,
      'settledNowMinor': settledNowMinor,
      'paymentMethod': paymentMethod.name,
      'paymentDueDate': dueDate,
      // Only hashed when present, so confirms without offsets keep their hash.
      if (offsetTargetOrderIds.isNotEmpty)
        'offsetTargetOrderIds': offsetTargetOrderIds,
    };
    final built = _build(operation: SalesReturnExchangeOperation.confirm, payload: payload);
    return SalesReturnExchangeAttempt<ReturnExchangeConfirmRequest>(
      operation: SalesReturnExchangeOperation.confirm,
      request: ReturnExchangeConfirmRequest(
        commandId: built.attemptId,
        returnExchangeId: trimmedReturnExchangeId,
        idempotencyKey: built.idempotencyKey,
        payloadHash: built.payloadHash,
        correlationId: context.correlationId,
        expectedVersion: expectedVersion,
        settledNowMinor: settledNowMinor,
        paymentMethod: paymentMethod,
        paymentDueDate: paymentDueDate,
        offsetTargetOrderIds: List.unmodifiable(offsetTargetOrderIds),
      ),
      canonicalPayloadJson: built.canonicalJson,
      payloadHash: built.payloadHash,
    );
  }

  _BuiltAttempt _build({
    required SalesReturnExchangeOperation operation,
    required Map<String, Object?> payload,
  }) {
    final canonicalJson = jsonEncode(_sort(payload));
    final payloadHash = sha256.convert(utf8.encode(canonicalJson)).toString();
    final attemptId = _newAttemptId();
    final operationName = switch (operation) {
      SalesReturnExchangeOperation.start => 'start',
      SalesReturnExchangeOperation.update => 'update',
      SalesReturnExchangeOperation.discard => 'discard',
      SalesReturnExchangeOperation.confirm => 'confirm',
    };
    return _BuiltAttempt(
      attemptId: attemptId,
      idempotencyKey: 'return-exchange:$operationName:$attemptId',
      canonicalJson: canonicalJson,
      payloadHash: payloadHash,
    );
  }

  static _AttemptContext _requireContext({
    required String tenantId,
    required String actorId,
    required String correlationId,
  }) {
    final trimmedTenantId = tenantId.trim();
    final trimmedActorId = actorId.trim();
    final trimmedCorrelationId = correlationId.trim();
    if (trimmedTenantId.isEmpty || trimmedActorId.isEmpty || trimmedCorrelationId.isEmpty) {
      throw const AppException('CONTEXT_INVALID');
    }
    return _AttemptContext(
      tenantId: trimmedTenantId,
      actorId: trimmedActorId,
      correlationId: trimmedCorrelationId,
    );
  }

  static List<Map<String, Object?>> _normalizeLines(List<ReturnExchangeLineInput> lines) {
    final normalized = <Map<String, Object?>>[
      for (final line in lines)
        <String, Object?>{
          'conditionCode': _normalizeOptionalCode(line.conditionCode),
          'kind': switch (line.kind) {
            ReturnExchangeLineKind.returnLine => 'returnLine',
            ReturnExchangeLineKind.exchangeLine => 'exchangeLine',
          },
          'originalSalesOrderLineId': line.originalSalesOrderLineId?.trim(),
          'sourceExchangeLineId': line.sourceExchangeLineId?.trim(),
          'productId': line.productId.trim(),
          'productUnitId': line.productUnitId.trim(),
          'quantityMicros': line.quantity.quantityMicros,
          'reasonCode': _normalizeOptionalCode(line.reasonCode),
          'exchangeProductSnapshot': line.exchangeProductSnapshot == null
              ? null
              : <String, Object?>{
                  'productId': line.exchangeProductSnapshot!.productId.trim(),
                  'sku': line.exchangeProductSnapshot!.sku?.trim(),
                  'displayName': line.exchangeProductSnapshot!.displayName.trim(),
                },
          'exchangeUnitSnapshot': line.exchangeUnitSnapshot == null
              ? null
              : <String, Object?>{
                  'productUnitId': line.exchangeUnitSnapshot!.productUnitId.trim(),
                  'unitCode': line.exchangeUnitSnapshot!.unitCode?.trim(),
                  'unitName': line.exchangeUnitSnapshot!.unitName.trim(),
                },
          'exchangeUnitPrice': line.exchangeUnitPrice == null
              ? null
              : <String, Object?>{
                  'amountMinor': line.exchangeUnitPrice!.amountMinor,
                  'currencyCode': line.exchangeUnitPrice!.currencyCode.trim().toUpperCase(),
                },
        },
    ];
    normalized.sort((a, b) {
      final kind = (a['kind'] as String).compareTo(b['kind'] as String);
      if (kind != 0) return kind;
      final original = (a['originalSalesOrderLineId'] as String? ?? '').compareTo(
        b['originalSalesOrderLineId'] as String? ?? '',
      );
      if (original != 0) return original;
      final sourceExchange = (a['sourceExchangeLineId'] as String? ?? '').compareTo(
        b['sourceExchangeLineId'] as String? ?? '',
      );
      if (sourceExchange != 0) return sourceExchange;
      final product = (a['productId'] as String).compareTo(b['productId'] as String);
      if (product != 0) return product;
      return (a['productUnitId'] as String).compareTo(b['productUnitId'] as String);
    });
    for (final line in normalized) {
      if ((line['productId'] as String).isEmpty ||
          (line['productUnitId'] as String).isEmpty ||
          (line['quantityMicros'] as int) <= 0) {
        throw const AppException('CONTEXT_INVALID');
      }
      final kind = line['kind'] as String;
      final reason = line['reasonCode'] as String?;
      final condition = line['conditionCode'] as String?;
      final original = line['originalSalesOrderLineId'] as String?;
      final sourceExchange = line['sourceExchangeLineId'] as String?;
      final hasOriginal = original != null && original.isNotEmpty;
      final hasExchange = sourceExchange != null && sourceExchange.isNotEmpty;
      if (kind == 'returnLine') {
        if (hasOriginal == hasExchange) {
          throw const AppException('CONTEXT_INVALID');
        }
      } else if (reason != null || condition != null || hasOriginal || hasExchange) {
        throw const AppException('CONTEXT_INVALID');
      }
    }
    return normalized;
  }

  static String? _normalizeOptionalCode(String? value) {
    if (value == null) return null;
    final trimmed = value.trim().toUpperCase();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _entrySourceWire(ReturnExchangeEntrySource source) => switch (source) {
    ReturnExchangeEntrySource.standard => 'standard',
    ReturnExchangeEntrySource.fullReturnFromCancelAttempt => 'full_return_from_cancel_attempt',
  };

  static List<ReturnExchangeLineInput> _toLineInputs(List<Map<String, Object?>> lines) {
    return [
      for (final line in lines)
        ReturnExchangeLineInput(
          kind: switch (line['kind'] as String) {
            'returnLine' => ReturnExchangeLineKind.returnLine,
            _ => ReturnExchangeLineKind.exchangeLine,
          },
          productId: line['productId'] as String,
          productUnitId: line['productUnitId'] as String,
          quantity: QuantityDto(quantityMicros: line['quantityMicros'] as int),
          originalSalesOrderLineId: line['originalSalesOrderLineId'] as String?,
          sourceExchangeLineId: line['sourceExchangeLineId'] as String?,
          reasonCode: line['reasonCode'] as String?,
          conditionCode: line['conditionCode'] as String?,
          exchangeProductSnapshot: _productSnapshot(
            line['exchangeProductSnapshot'] as Map<String, Object?>?,
          ),
          exchangeUnitSnapshot: _unitSnapshot(
            line['exchangeUnitSnapshot'] as Map<String, Object?>?,
          ),
          exchangeUnitPrice: _money(line['exchangeUnitPrice'] as Map<String, Object?>?),
        ),
    ];
  }

  static ProductSnapshotDto? _productSnapshot(Map<String, Object?>? json) {
    if (json == null) return null;
    return ProductSnapshotDto(
      productId: json['productId'] as String,
      sku: json['sku'] as String?,
      displayName: json['displayName'] as String,
    );
  }

  static ProductUnitSnapshotDto? _unitSnapshot(Map<String, Object?>? json) {
    if (json == null) return null;
    return ProductUnitSnapshotDto(
      productUnitId: json['productUnitId'] as String,
      unitCode: json['unitCode'] as String?,
      unitName: json['unitName'] as String,
    );
  }

  static MoneyDto? _money(Map<String, Object?>? json) {
    if (json == null) return null;
    return MoneyDto(
      amountMinor: json['amountMinor'] as int,
      currencyCode: json['currencyCode'] as String,
    );
  }

  static Object? _sort(Object? value) {
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      return <String, Object?>{for (final key in keys) key: _sort(value[key])};
    }
    if (value is List) return [for (final item in value) _sort(item)];
    return value;
  }
}

final class _AttemptContext {
  const _AttemptContext({
    required this.tenantId,
    required this.actorId,
    required this.correlationId,
  });

  final String tenantId;
  final String actorId;
  final String correlationId;
}

final class _BuiltAttempt {
  const _BuiltAttempt({
    required this.attemptId,
    required this.idempotencyKey,
    required this.canonicalJson,
    required this.payloadHash,
  });

  final String attemptId;
  final String idempotencyKey;
  final String canonicalJson;
  final String payloadHash;
}
