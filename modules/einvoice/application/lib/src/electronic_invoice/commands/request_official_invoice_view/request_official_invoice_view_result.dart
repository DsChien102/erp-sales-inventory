import 'package:vet45_einvoice_domain/domain.dart';

final class OfficialInvoiceViewDto {
  const OfficialInvoiceViewDto({
    this.operationId,
    this.status = InvoiceDocumentStatus.pending,
    this.viewerUrl,
    this.token,
    this.expiresAt,
  });

  /// Stable async operation identity. Replays return the same operation.
  final String? operationId;
  final InvoiceDocumentStatus status;
  final String? viewerUrl;
  final String? token;
  final DateTime? expiresAt;
}
