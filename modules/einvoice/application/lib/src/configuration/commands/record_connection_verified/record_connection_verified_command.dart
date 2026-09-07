import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Internal — worker records MISA auth + capability sync outcome.
final class RecordConnectionVerifiedCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  RecordConnectionVerifiedCommand({
    String? id,
    required this.tenantId,
    required this.connectionId,
    required this.expectedConnectionVersion,
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
  final int expectedConnectionVersion;
  final ProviderConnectionStatus status;
  final ProviderCapabilitiesSnapshot? capabilities;
  final DateTime? verifiedAt;
  final String? correlationId;

  @override
  Map<String, dynamic> toJson() {
    return stripInternalCommandRowId(<String, dynamic>{
      'tenant_id': tenantId,
      'connection_id': connectionId,
      'expected_connection_version': expectedConnectionVersion,
      'status': status.name,
      if (capabilities != null)
        'capabilities': {
          'supports_email_delivery': capabilities!.supportsEmailDelivery,
          'supports_preview': capabilities!.supportsPreview,
          'supports_delivery_result_observation': capabilities!.supportsDeliveryResultObservation,
          'template_count': capabilities!.templateCount,
          'supported_document_types': [
            for (final type in capabilities!.supportedDocumentTypes)
              switch (type) {
                InvoiceDocumentType.pdf => 'PDF',
                InvoiceDocumentType.xml => 'XML',
              },
          ],
          'templates': [
            for (final t in capabilities!.templates)
              {
                'template_id': t.templateId,
                'name': t.name,
                'serial': t.serial,
                'symbol': t.symbol,
                'is_mtt': t.isMtt,
                'is_available': t.isAvailable,
              },
          ],
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
      final rawTemplates = capsRaw['templates'];
      final templates = (rawTemplates is List)
          ? rawTemplates
                .whereType<Map>()
                .map(
                  (t) => ProviderTemplateRef(
                    templateId: t['template_id'] as String? ?? '',
                    name: t['name'] as String? ?? '',
                    serial: t['serial'] as String?,
                    symbol: t['symbol'] as String?,
                    isMtt: t['is_mtt'] as bool? ?? false,
                    isAvailable: t['is_available'] as bool? ?? true,
                  ),
                )
                .toList(growable: false)
          : const <ProviderTemplateRef>[];

      final rawDocTypes = capsRaw['supported_document_types'];
      final supportedDocumentTypes = <InvoiceDocumentType>{};
      if (rawDocTypes is List) {
        for (final item in rawDocTypes) {
          final normalized = (item as String).toUpperCase();
          if (normalized == 'PDF') {
            supportedDocumentTypes.add(InvoiceDocumentType.pdf);
          } else if (normalized == 'XML') {
            supportedDocumentTypes.add(InvoiceDocumentType.xml);
          }
        }
      }

      capabilities = ProviderCapabilitiesSnapshot(
        supportsEmailDelivery: capsRaw['supports_email_delivery'] as bool? ?? false,
        supportsPreview: capsRaw['supports_preview'] as bool? ?? false,
        supportsDeliveryResultObservation:
            capsRaw['supports_delivery_result_observation'] as bool? ?? false,
        templateCount: capsRaw['template_count'] as int? ?? 0,
        templates: templates,
        syncedAt: capsRaw['synced_at'] != null
            ? DateTime.parse(capsRaw['synced_at'] as String)
            : null,
        supportedDocumentTypes: supportedDocumentTypes,
      );
    }
    return RecordConnectionVerifiedCommand(
      id: id,
      tenantId: normalized['tenant_id'] as String,
      connectionId: normalized['connection_id'] as String,
      expectedConnectionVersion: normalized['expected_connection_version'] as int? ?? -1,
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
