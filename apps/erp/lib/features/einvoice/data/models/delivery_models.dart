import 'einvoice_enums.dart';

/// Single delivery record in an invoice's history.
final class InvoiceDeliveryItemDto {
  const InvoiceDeliveryItemDto({
    required this.deliveryId,
    required this.deliveryNo,
    required this.kind,
    required this.triggerType,
    required this.recipientEmail,
    required this.status,
    required this.initiatedByActorType,
    required this.initiatedByActorId,
    required this.startedAt,
    required this.completedAt,
    required this.failureCode,
  });

  final String deliveryId;
  final int deliveryNo;
  final DeliveryKind kind;
  final DeliveryTriggerType triggerType;
  final String recipientEmail;
  final DeliveryStatus status;
  final DeliveryActorType initiatedByActorType;
  final String? initiatedByActorId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? failureCode;
}

/// Delivery history read model.
final class InvoiceDeliveryHistoryDto {
  const InvoiceDeliveryHistoryDto({
    required this.deliveries,
    required this.displayState,
    required this.hasSecondaryAttention,
  });

  final List<InvoiceDeliveryItemDto> deliveries;
  final DeliveryDisplayState displayState;
  final bool hasSecondaryAttention;
}

/// Result of sending an electronic invoice.
final class SendInvoiceResultDto {
  const SendInvoiceResultDto({
    required this.deliveryId,
    required this.status,
  });

  final String deliveryId;
  final DeliveryStatus status;
}

/// Context for the send invoice sheet.
final class SendInvoiceSheetContextDto {
  const SendInvoiceSheetContextDto({
    required this.mode,
    required this.suggestedEmail,
    required this.suggestedEmailSource,
    required this.history,
    required this.operationLocked,
    required this.displayState,
  });

  final SendInvoiceSheetMode mode;
  final String? suggestedEmail;
  final DeliveryRecipientSource? suggestedEmailSource;
  final List<InvoiceDeliveryItemDto> history;
  final bool operationLocked;
  final DeliveryDisplayState displayState;
}

