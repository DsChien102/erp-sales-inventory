import 'package:vet45_einvoice_domain/domain.dart';

final class OfficialViewResultRecord {
  const OfficialViewResultRecord({
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.requestId,
    required this.status,
    this.viewerUrl,
    this.viewerToken,
    this.expiresAt,
    this.failureCode,
    this.failureMessage,
    this.failureSource,
  });

  final String tenantId;
  final String electronicInvoiceId;
  final String requestId;
  final InvoiceDocumentStatus status;
  final String? viewerUrl;
  final String? viewerToken;
  final DateTime? expiresAt;
  final String? failureCode;
  final String? failureMessage;
  final FailureSource? failureSource;
}
