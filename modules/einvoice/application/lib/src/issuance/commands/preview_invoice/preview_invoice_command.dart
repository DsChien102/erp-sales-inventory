import 'package:vet45_shared_application/application.dart';

/// Internal — worker builds a MISA unpublished preview (durable). Creates no
/// issuance state (DR-02).
final class PreviewInvoiceCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  PreviewInvoiceCommand({
    String? id,
    required this.tenantId,
    required this.salesOrderId,
    required this.previewRequestId,
    required this.providerConnectionId,
    required this.orderVersion,
    required this.canonicalInvoice,
    this.workerAttemptNumber = 1,
  }) : super(id);

  static const type = 'einvoice.preview_invoice';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String salesOrderId;
  final String previewRequestId;
  final String providerConnectionId;
  final int orderVersion;
  final Map<String, Object?> canonicalInvoice;
  final int workerAttemptNumber;

  @override
  Map<String, dynamic> toJson() {
    return stripInternalCommandRowId(<String, dynamic>{
      'tenant_id': tenantId,
      'sales_order_id': salesOrderId,
      'preview_request_id': previewRequestId,
      'provider_connection_id': providerConnectionId,
      'order_version': orderVersion,
      'canonical_invoice': canonicalInvoice,
    });
  }

  factory PreviewInvoiceCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final n = normalizeInternalCommandDeserializeJson(json, rowId: id);
    return PreviewInvoiceCommand(
      id: id,
      tenantId: n['tenant_id'] as String,
      salesOrderId: n['sales_order_id'] as String,
      previewRequestId: n['preview_request_id'] as String,
      providerConnectionId: n['provider_connection_id'] as String,
      orderVersion: (n['order_version'] as num).toInt(),
      canonicalInvoice: Map<String, Object?>.from(n['canonical_invoice'] as Map),
      workerAttemptNumber: readInternalCommandWorkerAttemptNumber(n),
    );
  }
}
