import 'package:vet45_shared_application/application.dart';

final class PollProviderObservationCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  PollProviderObservationCommand({
    String? id,
    required this.tenantId,
    required this.providerConnectionId,
    required this.electronicInvoiceId,
    required this.triggerId,
    required this.correlationId,
    this.workerAttemptNumber = 1,
  }) : super(id);

  static const type = 'einvoice.poll_provider_observation';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String providerConnectionId;
  final String electronicInvoiceId;
  final String triggerId;
  final String correlationId;
  final int workerAttemptNumber;

  @override
  Map<String, dynamic> toJson() => stripInternalCommandRowId({
    'tenant_id': tenantId,
    'provider_connection_id': providerConnectionId,
    'electronic_invoice_id': electronicInvoiceId,
    'trigger_id': triggerId,
    'correlation_id': correlationId,
  });

  factory PollProviderObservationCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final normalized = normalizeInternalCommandDeserializeJson(json, rowId: id);
    final triggerId = normalized['trigger_id'] as String;
    if (triggerId.trim().isEmpty) {
      throw FormatException('trigger_id must not be blank');
    }
    return PollProviderObservationCommand(
      id: id,
      tenantId: normalized['tenant_id'] as String,
      providerConnectionId: normalized['provider_connection_id'] as String,
      electronicInvoiceId: normalized['electronic_invoice_id'] as String,
      triggerId: triggerId,
      correlationId: normalized['correlation_id'] as String,
      workerAttemptNumber: readInternalCommandWorkerAttemptNumber(normalized),
    );
  }
}
