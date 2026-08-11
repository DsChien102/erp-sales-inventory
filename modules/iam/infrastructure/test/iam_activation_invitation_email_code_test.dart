import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_resend/vet45_resend.dart';

void main() {
  group('activation_invitation email carries the activation code', () {
    test('renderer embeds code in html and text', () {
      final rendered = EmailTemplateRenderer.render(
        templateId: EmailTemplateId.activationInvitation,
        toEmail: 'owner@example.com',
        locale: 'vi',
        refs: const <String, String>{'tenant_id': 'ten-1'},
        code: 'ABCD2345',
      );

      expect(rendered.html, contains('ABCD2345'));
      expect(rendered.text, contains('ABCD2345'));
    });

    test('renders without a code (no code block, still valid)', () {
      final rendered = EmailTemplateRenderer.render(
        templateId: EmailTemplateId.activationInvitation,
        toEmail: 'owner@example.com',
        locale: 'vi',
        refs: const <String, String>{},
      );

      expect(rendered.subject, contains('tham gia'));
      expect(rendered.html, isNotEmpty);
    });

    test('gateway decodes transient secret payload for activation_invitation', () async {
      final resend = FakeResendClient();
      final gateway = IamEmailSenderGateway(resendClient: resend);

      final result = await gateway.send(
        templateId: EmailTemplateId.activationInvitation,
        toEmail: 'owner@example.com',
        locale: 'vi',
        refs: const <String, String>{},
        secretPayloadCiphertext: 'transient:QUJDRDIzNDU=', // base64 for ABCD2345
      );

      expect(result.isSuccess, isTrue);
      expect(resend.sendCount, 1);
      expect(resend.lastHtmlBody, contains('ABCD2345'));
    });
  });
}
