import 'package:vet45_shared_application/application.dart';

/// Internal — durable worker publishes a canonical invoice to MISA at most once
/// per attempt dispatch barrier (AD-03).
final class PublishInvoiceCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  PublishInvoiceCommand({
    String? id,
    required this.tenantId,
    required this.attemptId,
    required this.canonicalInvoice,
    required this.payloadHash,
    required this.idempotencyKey,
  }) : super(id);

  static const type = 'einvoice.publish_invoice';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String attemptId;
  final Map<String, Object?> canonicalInvoice;
  final String payloadHash;
  final String idempotencyKey;

  @override
  Map<String, dynamic> toJson() {
    return stripInternalCommandRowId(<String, dynamic>{
      'tenant_id': tenantId,
      'attempt_id': attemptId,
      'canonical_invoice': canonicalInvoice,
      'payload_hash': payloadHash,
      'idempotency_key': idempotencyKey,
    });
  }

  factory PublishInvoiceCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final n = normalizeInternalCommandDeserializeJson(json, rowId: id);
    return PublishInvoiceCommand(
      id: id,
      tenantId: n['tenant_id'] as String,
      attemptId: n['attempt_id'] as String,
      canonicalInvoice: Map<String, Object?>.from(n['canonical_invoice'] as Map),
      payloadHash: n['payload_hash'] as String,
      idempotencyKey: n['idempotency_key'] as String,
    );
  }
}
