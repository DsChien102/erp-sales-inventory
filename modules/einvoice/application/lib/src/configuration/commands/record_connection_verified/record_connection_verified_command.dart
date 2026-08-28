import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Internal — worker records MISA auth + capability sync outcome.
final class RecordConnectionVerifiedCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  RecordConnectionVerifiedCommand({
    String? id,
    required this.tenantId,
    required this.connectionId,
    required this.status,
    this.capabilities,
    this.verifiedAt,
    this.correlationId,
  }) : super(id);

  static const type = 'einvoice.configuration.record_connection_verified';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String connectionId;
  final ProviderConnectionStatus status;
  final ProviderCapabilitiesSnapshot? capabilities;
  final DateTime? verifiedAt;
  final String? correlationId;

  @override
  Map<String, dynamic> toJson() {
    return stripInternalCommandRowId(<String, dynamic>{
      'tenant_id': tenantId,
      'connection_id': connectionId,
      'status': status.name,
      if (capabilities != null)
        'capabilities': {
          'supports_email_delivery': capabilities!.supportsEmailDelivery,
          'template_count': capabilities!.templateCount,
          if (capabilities!.syncedAt != null)
            'synced_at': capabilities!.syncedAt!.toUtc().toIso8601String(),
        },
      if (verifiedAt != null) 'verified_at': verifiedAt!.toUtc().toIso8601String(),
      if (correlationId != null) 'correlation_id': correlationId,
    });
  }

  factory RecordConnectionVerifiedCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final normalized = normalizeInternalCommandDeserializeJson(
      json,
      rowId: id,
    );
    final capsRaw = normalized['capabilities'];
    ProviderCapabilitiesSnapshot? capabilities;
    if (capsRaw is Map) {
      capabilities = ProviderCapabilitiesSnapshot(
        supportsEmailDelivery: capsRaw['supports_email_delivery'] as bool? ?? false,
        templateCount: capsRaw['template_count'] as int? ?? 0,
        syncedAt: capsRaw['synced_at'] != null
            ? DateTime.parse(capsRaw['synced_at'] as String)
            : null,
      );
    }
    return RecordConnectionVerifiedCommand(
      id: id,
      tenantId: normalized['tenant_id'] as String,
      connectionId: normalized['connection_id'] as String,
      status: ProviderConnectionStatus.values.byName(
        normalized['status'] as String,
      ),
      capabilities: capabilities,
      verifiedAt: normalized['verified_at'] != null
          ? DateTime.parse(normalized['verified_at'] as String)
          : null,
      correlationId: normalized['correlation_id'] as String?,
    );
  }
}
