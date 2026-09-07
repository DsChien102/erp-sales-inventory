import 'package:vet45_shared_application/application.dart';

/// Internal — worker post-auth capability sync (durable internal command).
final class SyncProviderCapabilitiesCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  SyncProviderCapabilitiesCommand({
    String? id,
    required this.tenantId,
    required this.connectionId,
    required this.expectedConnectionVersion,
    this.correlationId,
  }) : super(id);

  static const type = 'einvoice.sync_capabilities';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String connectionId;
  final int expectedConnectionVersion;
  final String? correlationId;

  @override
  Map<String, dynamic> toJson() {
    return stripInternalCommandRowId(<String, dynamic>{
      'tenant_id': tenantId,
      'connection_id': connectionId,
      'expected_connection_version': expectedConnectionVersion,
      if (correlationId != null) 'correlation_id': correlationId,
    });
  }

  factory SyncProviderCapabilitiesCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final normalized = normalizeInternalCommandDeserializeJson(
      json,
      rowId: id,
    );
    return SyncProviderCapabilitiesCommand(
      id: id,
      tenantId: normalized['tenant_id'] as String,
      connectionId: normalized['connection_id'] as String,
      expectedConnectionVersion: normalized['expected_connection_version'] as int? ?? -1,
      correlationId: normalized['correlation_id'] as String?,
    );
  }
}
