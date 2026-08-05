import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_resend/vet45_resend.dart';

String _ciphertextFor(String rawToken) =>
    'transient:${base64.encode(utf8.encode(rawToken))}';

void main() {
  group('tenant_invitation email carries the invitation code', () {
    test('renderer embeds code in html and text', () {
      final rendered = EmailTemplateRenderer.render(
        templateId: EmailTemplateId.tenantInvitation,
        toEmail: 'invitee@example.com',
        locale: 'vi',
        refs: const <String, String>{'invitation_id': 'inv-1'},
        code: 'RAW-TOKEN-123',
      );

      expect(rendered.html, contains('RAW-TOKEN-123'));
      expect(rendered.text, contains('RAW-TOKEN-123'));
    });

    test('gateway decodes secret payload and sends code', () async {
      final resend = FakeResendClient();
      final gateway = IamEmailSenderGateway(resendClient: resend);

      final result = await gateway.send(
        templateId: EmailTemplateId.tenantInvitation,
        toEmail: 'invitee@example.com',
        locale: 'vi',
        refs: const <String, String>{'invitation_id': 'inv-1'},
        secretPayloadCiphertext: _ciphertextFor('RAW-TOKEN-123'),
      );

      expect(result.isSuccess, isTrue);
      expect(resend.sendCount, 1);
      expect(resend.lastHtmlBody, contains('RAW-TOKEN-123'));
      expect(resend.lastTextBody, contains('RAW-TOKEN-123'));
    });

    test('gateway fails without sending when secret payload is missing', () async {
      final resend = FakeResendClient();
      final gateway = IamEmailSenderGateway(resendClient: resend);

      final result = await gateway.send(
        templateId: EmailTemplateId.tenantInvitation,
        toEmail: 'invitee@example.com',
        locale: 'vi',
        refs: const <String, String>{'invitation_id': 'inv-1'},
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('tenant_invitation'));
      expect(resend.sendCount, 0);
    });

    test('raw token never leaks into refs-derived subject', () async {
      final rendered = EmailTemplateRenderer.render(
        templateId: EmailTemplateId.tenantInvitation,
        toEmail: 'invitee@example.com',
        locale: 'vi',
        refs: const <String, String>{'invitation_id': 'inv-1'},
        code: 'RAW-TOKEN-123',
      );

      expect(rendered.subject, isNot(contains('RAW-TOKEN-123')));
    });

    test('tenant_invitation shows the 8-char code contiguously (no dash)', () {
      final rendered = EmailTemplateRenderer.render(
        templateId: EmailTemplateId.tenantInvitation,
        toEmail: 'invitee@example.com',
        locale: 'vi',
        refs: const <String, String>{'invitation_id': 'inv-1'},
        code: 'K7P29XQM',
      );
      expect(rendered.html, contains('K7P29XQM'));
      expect(rendered.text, contains('K7P29XQM'));
      expect(rendered.html, isNot(contains('K7P2-9XQM')));
    });
  });
}
