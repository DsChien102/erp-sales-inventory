import 'package:vet45_shared_application/application.dart';

import '../../shared/email_template_id.dart';

/// Durable internal command: deliver one email via the notification provider.
final class SendEmailDeliveryCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  SendEmailDeliveryCommand({
    String? id,
    required this.tenantId,
    required this.templateId,
    required this.toEmail,
    required this.correlationId,
    required this.outcomeId,
    this.locale = 'vi',
    this.refs = const <String, String>{},
    this.appLinkUrl,
  }) : super(id);

  static const type = 'iam.notification.send_email_delivery';

  @override
  String get commandType => type;

  @override
  final String tenantId;

  final EmailTemplateId templateId;
  final String toEmail;
  final String correlationId;
  final String outcomeId;
  final String locale;
  final Map<String, String> refs;
  final String? appLinkUrl;

  @override
  Map<String, dynamic> toJson() {
    return stripInternalCommandRowId(<String, dynamic>{
      'tenant_id': tenantId,
      'template_id': templateId.wireValue,
      'to_email': toEmail,
      'correlation_id': correlationId,
      'outcome_id': outcomeId,
      'locale': locale,
      'refs': refs,
      if (appLinkUrl != null) 'app_link_url': appLinkUrl,
    });
  }

  factory SendEmailDeliveryCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final normalized = normalizeInternalCommandDeserializeJson(
      json,
      rowId: id,
    );
    final refsRaw = normalized['refs'];
    final refs = <String, String>{};
    if (refsRaw is Map) {
      for (final entry in refsRaw.entries) {
        refs[entry.key.toString()] = entry.value.toString();
      }
    }

    return SendEmailDeliveryCommand(
      id: id,
      tenantId: normalized['tenant_id'] as String,
      templateId: EmailTemplateId.fromWire(
        normalized['template_id'] as String,
      ),
      toEmail: normalized['to_email'] as String,
      correlationId: normalized['correlation_id'] as String,
      outcomeId: normalized['outcome_id'] as String,
      locale: (normalized['locale'] as String?) ?? 'vi',
      refs: refs,
      appLinkUrl: normalized['app_link_url'] as String?,
    );
  }
}
