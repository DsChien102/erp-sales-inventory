import 'package:test/test.dart';
import 'package:vet45_iam_application/testing.dart';

void main() {
  group('FakeEmailDeliveryPort', () {
    test('notify_queued_ok returns queued outcome', () async {
      final port = FakeEmailDeliveryPort(
        scenario: FakeEmailDeliveryScenario.notifyQueuedOk,
      );
      final outcome = await port.enqueue(
        const EnqueueEmailDeliveryRequest(
          templateId: EmailTemplateId.tenantInvitation,
          toEmail: 'a@b.c',
          correlationId: 'corr-1',
          tenantId: 'tenant-1',
        ),
      );
      expect(outcome.status, EmailDeliveryStatus.queued);
      expect(outcome.providerMessageId, isNull);
      expect(port.enqueued, hasLength(1));
    });

    test('notify_sent_ok returns sent + messageId', () async {
      final port = FakeEmailDeliveryPort(
        scenario: FakeEmailDeliveryScenario.notifySentOk,
      );
      final outcome = await port.enqueue(
        const EnqueueEmailDeliveryRequest(
          templateId: EmailTemplateId.activationInvitation,
          toEmail: 'a@b.c',
          correlationId: 'corr-2',
          tenantId: EmailDeliveryConstants.platformTenantId,
        ),
      );
      expect(outcome.status, EmailDeliveryStatus.sent);
      expect(outcome.providerMessageId, startsWith('re_fake_'));
    });

    test('notify_failed returns failed', () async {
      final port = FakeEmailDeliveryPort(
        scenario: FakeEmailDeliveryScenario.notifyFailed,
      );
      final outcome = await port.enqueue(
        const EnqueueEmailDeliveryRequest(
          templateId: EmailTemplateId.passwordResetCode,
          toEmail: 'a@b.c',
          correlationId: 'corr-3',
          tenantId: EmailDeliveryConstants.platformTenantId,
        ),
      );
      expect(outcome.status, EmailDeliveryStatus.failed);
      expect(outcome.error, 'resend_5xx');
    });

    test('notify_rate_limited returns failed with 429 hint', () async {
      final port = FakeEmailDeliveryPort(
        scenario: FakeEmailDeliveryScenario.notifyRateLimited,
      );
      final outcome = await port.enqueue(
        const EnqueueEmailDeliveryRequest(
          templateId: EmailTemplateId.securityNotification,
          toEmail: 'a@b.c',
          correlationId: 'corr-4',
          tenantId: 'tenant-1',
        ),
      );
      expect(outcome.status, EmailDeliveryStatus.failed);
      expect(outcome.error, 'resend_429_rate_limited');
    });
  });
}
