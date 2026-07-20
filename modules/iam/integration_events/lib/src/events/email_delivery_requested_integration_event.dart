import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Integration event: email delivery requested (outbox → inbox self-consume).
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
    this.appLinkUrl,
  }) : super(eventType: type);

  static const type = 'iam.email.delivery_requested';

  final String templateId;
  final String toEmail;
  final String correlationId;
  final String outcomeId;
  final String locale;
  final Map<String, String> refs;
  final String? appLinkUrl;

  @override
  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'id': id,
      'tenant_id': tenantId,
      'template_id': templateId,
      'to_email': toEmail,
      'correlation_id': correlationId,
      'outcome_id': outcomeId,
      'locale': locale,
      'refs': refs,
      if (appLinkUrl != null) 'app_link_url': appLinkUrl,
      'occurred_on': occurredOn.toUtc().toIso8601String(),
    };
  }

  factory EmailDeliveryRequestedIntegrationEvent.fromPayload(
    Map<String, dynamic> json,
  ) {
    final refsRaw = json['refs'];
    final refs = <String, String>{};
    if (refsRaw is Map) {
      for (final entry in refsRaw.entries) {
        refs[entry.key.toString()] = entry.value.toString();
      }
    }

    return EmailDeliveryRequestedIntegrationEvent(
      id: TenantScopedIntegrationEvent.resolveId(json),
      occurredOn: json['occurred_on'] is String
          ? DateTime.parse(json['occurred_on'] as String).toUtc()
          : DateTime.now().toUtc(),
      tenantId: json['tenant_id'] as String,
      templateId: json['template_id'] as String,
      toEmail: json['to_email'] as String,
      correlationId: json['correlation_id'] as String,
      outcomeId: json['outcome_id'] as String,
      locale: (json['locale'] as String?) ?? 'vi',
      refs: refs,
      appLinkUrl: json['app_link_url'] as String?,
    );
  }
}
