import 'package:vet45_einvoice_domain/domain.dart';

final class OfficialViewResultRecord {
  const OfficialViewResultRecord({
    required this.tenantId,
    required this.operationId,
    required this.status,
    this.viewerUrl,
    this.viewerToken,
    this.expiresAt,
    this.failureCode,
    this.failureMessage,
    required this.providerInteractionReference,
    required this.expectedVersion,
  });

  final String tenantId;
  final String operationId;
  final InvoiceDocumentStatus status;
  final String? viewerUrl;
  final String? viewerToken;
  final DateTime? expiresAt;
  final String? failureCode;
  final String? failureMessage;
  final String providerInteractionReference;
  final int expectedVersion;
}
