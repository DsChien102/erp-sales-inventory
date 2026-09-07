import 'package:vet45_einvoice_domain/domain.dart';

/// One immutable business delivery in an invoice's history.
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
