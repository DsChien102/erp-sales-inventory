import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/models.dart';

String deliveryStatusLabel(DeliveryStatus status) => switch (status) {
  DeliveryStatus.processing => 'Đang gửi',
  DeliveryStatus.succeeded => 'Đã gửi',
  DeliveryStatus.failed => 'Gửi lỗi',
  DeliveryStatus.unknown => 'Không xác định kết quả',
};

VComponentTone deliveryStatusTone(DeliveryStatus status) => switch (status) {
  DeliveryStatus.processing => VComponentTone.primary,
  DeliveryStatus.succeeded => VComponentTone.success,
  DeliveryStatus.failed => VComponentTone.danger,
  DeliveryStatus.unknown => VComponentTone.warning,
};

/// One delivery attempt row for SG07-D01 history.
final class InvoiceDeliveryHistoryRowVm {
  const InvoiceDeliveryHistoryRowVm({
    required this.deliveryId,
    required this.deliveryNo,
    required this.statusLabel,
    required this.recipientEmail,
    required this.occurredAt,
    required this.actorLabel,
    required this.tone,
  });

  factory InvoiceDeliveryHistoryRowVm.fromDto(InvoiceDeliveryItemDto dto) {
    final occurredAt = dto.completedAt ?? dto.startedAt;
    return InvoiceDeliveryHistoryRowVm(
      deliveryId: dto.deliveryId,
      deliveryNo: dto.deliveryNo,
      statusLabel: deliveryStatusLabel(dto.status),
      recipientEmail: dto.recipientEmail,
      occurredAt: occurredAt.toLocal(),
      actorLabel: dto.initiatedByActorType == DeliveryActorType.system ? 'Tự động' : 'Người dùng',
      tone: deliveryStatusTone(dto.status),
    );
  }

  final String deliveryId;
  final int deliveryNo;
  final String statusLabel;
  final String recipientEmail;
  final DateTime occurredAt;
  final String actorLabel;
  final VComponentTone tone;
}
