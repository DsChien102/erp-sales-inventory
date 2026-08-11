import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Integration event: email delivery requested (outbox → inbox self-consume).
///
/// Envelope v1 — see TH-01 `07-api-contracts.md` §S-NOTIFY.
///
/// Platform-scoped mail uses `tenant_id: null` in the payload. Messaging
/// partition rows still use [platformMessagingTenantId] because outbox/inbox
/// tables require a non-null tenant key.
final class EmailDeliveryRequestedIntegrationEvent
    extends TenantScopedIntegrationEvent {
  EmailDeliveryRequestedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.templateId,
    required this.toEmail,
    required this.correlationId,
    required this.outcomeId,
    this.locale = 'vi',
    this.refs = const <String, String>{},
    this.secretPayloadCiphertext,
    this.eventVersion = 1,
  }) : super(eventType: type);

  static const type = 'iam.email.delivery_requested';
  static const currentEventVersion = 1;

  /// Outbox/inbox partition key for platform-scoped mail (not a domain tenant).
  static const platformMessagingTenantId =
      '00000000-0000-0000-0000-000000000000';

  final String templateId;
  final String toEmail;
  final String correlationId;
  final String outcomeId;
  final String locale;
  final Map<String, String> refs;

  /// Optional encrypted transient secret channel (key outside DB).
  /// Raw tokens must never appear in [refs] or normal JSON fields.
  final String? secretPayloadCiphertext;

  final int eventVersion;

  bool get isPlatformScoped => tenantId == platformMessagingTenantId;

  @override
  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'event_version': eventVersion,
      'id': id,
      'occurred_on': occurredOn.toUtc().toIso8601String(),
      'tenant_id': isPlatformScoped ? null : tenantId,
      'template_id': templateId,
      'to_email': toEmail,
      'correlation_id': correlationId,
      'outcome_id': outcomeId,
      'locale': locale,
      'refs': refs,
      if (secretPayloadCiphertext != null)
        'secret_payload_ciphertext': secretPayloadCiphertext,
    };
  }

  factory EmailDeliveryRequestedIntegrationEvent.fromPayload(
    Map<String, dynamic> json,
  ) {
    final versionRaw = json['event_version'];
    if (versionRaw is! int && versionRaw is! num) {
      throw FormatException(
        'EmailDeliveryRequestedIntegrationEvent missing event_version',
        json,
      );
    }
    final eventVersion = (versionRaw as num).toInt();
    if (eventVersion != currentEventVersion) {
      throw FormatException(
        'Unsupported event_version=$eventVersion '
        '(expected $currentEventVersion)',
        json,
      );
    }

    final toEmail = json['to_email'];
    if (toEmail is! String || toEmail.trim().isEmpty) {
      throw FormatException(
        'EmailDeliveryRequestedIntegrationEvent missing to_email',
        json,
      );
    }
    final correlationId = json['correlation_id'];
    if (correlationId is! String || correlationId.trim().isEmpty) {
      throw FormatException(
        'EmailDeliveryRequestedIntegrationEvent missing correlation_id',
        json,
      );
    }
    final outcomeId = json['outcome_id'];
    if (outcomeId is! String || outcomeId.trim().isEmpty) {
      throw FormatException(
        'EmailDeliveryRequestedIntegrationEvent missing outcome_id',
        json,
      );
    }
    final templateId = json['template_id'];
    if (templateId is! String || templateId.trim().isEmpty) {
      throw FormatException(
        'EmailDeliveryRequestedIntegrationEvent missing template_id',
        json,
      );
    }

    final refsRaw = json['refs'];
    final refs = <String, String>{};
    if (refsRaw is Map) {
      for (final entry in refsRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value.toString();
        _rejectSecretInRefs(key, value);
        refs[key] = value;
      }
    }

    final tenantRaw = json['tenant_id'];
    final tenantId = tenantRaw == null || tenantRaw == ''
        ? platformMessagingTenantId
        : tenantRaw as String;

    return EmailDeliveryRequestedIntegrationEvent(
      id: TenantScopedIntegrationEvent.resolveId(json),
      occurredOn: json['occurred_on'] is String
          ? DateTime.parse(json['occurred_on'] as String).toUtc()
          : DateTime.now().toUtc(),
      tenantId: tenantId,
      templateId: templateId,
      toEmail: toEmail,
      correlationId: correlationId,
      outcomeId: outcomeId,
      locale: (json['locale'] as String?) ?? 'vi',
      refs: refs,
      secretPayloadCiphertext: json['secret_payload_ciphertext'] as String?,
      eventVersion: eventVersion,
    );
  }

  static void _rejectSecretInRefs(String key, String value) {
    final lowerKey = key.toLowerCase();
    const banned = <String>{
      'token',
      'raw_token',
      'otp',
      'password',
      'code',
      'session_token',
      'invitation_token',
    };
    if (banned.contains(lowerKey)) {
      throw FormatException(
        'refs must not contain secret material key=$key',
      );
    }
    if (value.length >= 16 &&
        RegExp(r'^[A-Za-z0-9\-_=+/]+$').hasMatch(value) &&
        lowerKey.contains('token')) {
      throw FormatException(
        'refs must not contain token-like secret material key=$key',
      );
    }
  }
}
