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

    test('handler skips stale tenant invitation delivery', () async {
      final sender = _RecordingEmailSender();
      final outcomes = _FakeOutcomeStore()..currentInvitationCorrelationById['inv-1'] = 'corr-new';
      final handler = SendEmailDeliveryCommandHandler(
        emailSender: sender,
        outcomes: outcomes,
      );

      await handler.handle(
        SendEmailDeliveryCommand(
          tenantId: '11111111-1111-1111-1111-111111111111',
          templateId: EmailTemplateId.tenantInvitation,
          toEmail: 'invitee@example.com',
          correlationId: 'corr-old',
          outcomeId: 'out-old',
          refs: const <String, String>{'invitation_id': 'inv-1'},
          secretPayloadCiphertext: 'transient:S1lYR0NGVFI=',
        ),
      );

      expect(sender.sendCount, 0);
      final outcome = outcomes.byCorrelation['corr-old'];
      expect(outcome, isNotNull);
      expect(outcome!.status, EmailDeliveryStatus.failed);
      expect(outcome.error, 'stale_invitation_delivery');
    });
  });
}

final class _RecordingEmailSender implements IEmailSenderGateway {
  int sendCount = 0;

  @override
  Future<EmailSendResult> send({
    required EmailTemplateId templateId,
    required String toEmail,
    required String locale,
    required Map<String, String> refs,
    String? appLinkUrl,
    String? secretPayloadCiphertext,
  }) async {
    sendCount++;
    return const EmailSendResult(isSuccess: true, messageId: 'msg-1');
  }
}

final class _FakeOutcomeStore implements IEmailDeliveryOutcomeStore {
  final Map<String, EmailDeliveryOutcomeDto> byCorrelation = <String, EmailDeliveryOutcomeDto>{};
  final Map<String, String> currentInvitationCorrelationById = <String, String>{};

  @override
  Future<String> record({
    required String correlationId,
    required EmailTemplateId templateId,
    required EmailDeliveryStatus status,
    String? tenantId,
    String? toEmailMasked,
    String? providerMessageId,
    String? error,
    String provider = EmailDeliveryConstants.providerResend,
    String? id,
  }) async {
    final resolvedId = id ?? 'outcome-${byCorrelation.length + 1}';
    byCorrelation[correlationId] = EmailDeliveryOutcomeDto(
      id: resolvedId,
      tenantId: tenantId,
      templateId: templateId,
      status: status,
      correlationId: correlationId,
      provider: provider,
      providerMessageId: providerMessageId,
      error: error,
      toEmailMasked: toEmailMasked,
    );
    return resolvedId;
  }

  @override
  Future<EmailDeliveryOutcomeDto?> getByCorrelationId(
    String correlationId,
  ) async {
    return byCorrelation[correlationId];
  }

  @override
  Future<bool> isCurrentTenantInvitationDelivery({
    required String invitationId,
    required String correlationId,
  }) async {
    final current = currentInvitationCorrelationById[invitationId];
    return current == null || current == correlationId;
  }
}
