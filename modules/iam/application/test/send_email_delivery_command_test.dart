import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  group('SendEmailDeliveryCommand', () {
    test('round-trips toJson / fromJson and exposes commandType', () {
      final command = SendEmailDeliveryCommand(
        id: 'cmd-1',
        tenantId: '11111111-1111-1111-1111-111111111111',
        templateId: EmailTemplateId.tenantInvitation,
        toEmail: 'invitee@example.com',
        correlationId: 'corr-1',
        outcomeId: 'out-1',
        locale: 'vi',
        refs: const <String, String>{'invitation_id': 'inv-1'},
      );

      expect(command.commandType, SendEmailDeliveryCommand.type);
      expect(command.commandType, 'iam.notification.send_email_delivery');

      final payload = command.toJson();
      expect(payload.containsKey('id'), isFalse);
      expect(payload['event_version'], 1);
      expect(payload.containsKey('app_link_url'), isFalse);

      final restored = SendEmailDeliveryCommand.fromJson(
        payload,
        id: 'cmd-1',
      );
      expect(restored.id, 'cmd-1');
      expect(restored.tenantId, command.tenantId);
      expect(restored.templateId, command.templateId);
      expect(restored.toEmail, command.toEmail);
      expect(restored.correlationId, command.correlationId);
      expect(restored.outcomeId, command.outcomeId);
      expect(restored.locale, command.locale);
      expect(restored.refs, command.refs);
    });

    test('platform tenant serializes tenant_id null and restores sentinel', () {
      final command = SendEmailDeliveryCommand(
        id: 'cmd-platform',
        tenantId: EmailDeliveryConstants.platformTenantId,
        templateId: EmailTemplateId.activationInvitation,
        toEmail: 'owner@example.com',
        correlationId: 'corr-p',
        outcomeId: 'out-p',
      );

      final payload = command.toJson();
      expect(payload['tenant_id'], isNull);
      expect(payload['event_version'], 1);

      final restored = SendEmailDeliveryCommand.fromJson(
        payload,
        id: 'cmd-platform',
      );
      expect(restored.tenantId, EmailDeliveryConstants.platformTenantId);
    });
  });
}
