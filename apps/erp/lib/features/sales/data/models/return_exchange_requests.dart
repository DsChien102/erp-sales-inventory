import 'package:erp/features/sales/data/models.dart';

/// Yêu cầu khởi tạo phiếu đổi/trả.
final class ReturnExchangeStartRequest {
  ReturnExchangeStartRequest({
    required this.commandId,
    required this.salesOrderId,
    required this.entrySource,
    required List<ReturnExchangeLineInput> lines,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.correlationId,
    required this.expectedVersion,
  }) : lines = List.unmodifiable(lines);

  final String commandId;
  final String salesOrderId;
  final ReturnExchangeEntrySource entrySource;
  final List<ReturnExchangeLineInput> lines;
  final String idempotencyKey;
  final String payloadHash;
  final String correlationId;
  final int expectedVersion;
}

/// Yêu cầu cập nhật dòng phiếu đổi/trả.
final class ReturnExchangeUpdateRequest {
  ReturnExchangeUpdateRequest({
    required this.commandId,
    required this.returnExchangeId,
    required List<ReturnExchangeLineInput> lines,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.correlationId,
    required this.expectedVersion,
  }) : lines = List.unmodifiable(lines);

  final String commandId;
  final String returnExchangeId;
  final List<ReturnExchangeLineInput> lines;
  final String idempotencyKey;
  final String payloadHash;
  final String correlationId;
  final int expectedVersion;
}

/// Yêu cầu huỷ nháp hoặc hoàn tất phiếu đổi/trả (chỉ cần id và version tuỳ chọn).
final class ReturnExchangeMutationRequest {
  const ReturnExchangeMutationRequest({
    required this.commandId,
    required this.returnExchangeId,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.correlationId,
    this.expectedVersion,
  });

  final String commandId;
  final String returnExchangeId;
  final String idempotencyKey;
  final String payloadHash;
  final String correlationId;
  final int? expectedVersion;
}

/// Yêu cầu xác nhận/quyết toán phiếu đổi/trả.
final class ReturnExchangeConfirmRequest {
  const ReturnExchangeConfirmRequest({
    required this.commandId,
    required this.returnExchangeId,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.correlationId,
    required this.expectedVersion,
    this.settledNowMinor,
    this.paymentMethod = SalesPaymentMethod.cash,
    this.paymentDueDate,
    this.offsetTargetOrderIds = const [],
  });

  final String commandId;
  final String returnExchangeId;
  final String idempotencyKey;
  final String payloadHash;
  final String correlationId;
  final int expectedVersion;
  final int? settledNowMinor;
  final List<String> offsetTargetOrderIds;
  final SalesPaymentMethod paymentMethod;
  final DateTime? paymentDueDate;
}

