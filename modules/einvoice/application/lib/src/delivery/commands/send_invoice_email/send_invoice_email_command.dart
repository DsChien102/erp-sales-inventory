import '../../shared/delivery_command_payload.dart';
import 'package:vet45_shared_application/application.dart';

/// Durable worker command — sends one invoice email attempt via provider.
///
/// Contains only identity fields; recipient and credentials load from DB.
final class SendInvoiceEmailCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  SendInvoiceEmailCommand({
    String? id,
    required this.tenantId,
    required this.deliveryId,
    required this.retryCount,
    this.workerAttemptNumber = 1,
  }) : super(id);

  static const type = 'einvoice.send_invoice_email';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String deliveryId;
  final int retryCount;
  final int workerAttemptNumber;

  @override
  Map<String, dynamic> toJson() => stripInternalCommandRowId(<String, dynamic>{
    'tenant_id': tenantId,
    'delivery_id': deliveryId,
    'retry_count': retryCount,
  });

  factory SendInvoiceEmailCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final n = normalizeInternalCommandDeserializeJson(json, rowId: id);
    final payload = DeliveryCommandPayload.fromJson(n);
    return SendInvoiceEmailCommand(
      id: id,
      tenantId: payload.tenantId,
      deliveryId: payload.deliveryId,
      retryCount: payload.retryCount,
      workerAttemptNumber: readInternalCommandWorkerAttemptNumber(n),
    );
  }
}
