import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_resend/vet45_resend.dart';

void main() {
  group('IamEmailSenderGateway passwordResetCode', () {
    test('renders code decoded from transient secret payload', () async {
      final resend = FakeResendClient();
      final gateway = IamEmailSenderGateway(resendClient: resend);
      final cipher = 'transient:${base64.encode(utf8.encode('123456'))}';

      final result = await gateway.send(
        templateId: EmailTemplateId.passwordResetCode,
        toEmail: 'lan@gmail.com',
        locale: 'vi',
        refs: const {'operation_id': 'op-1'},
        secretPayloadCiphertext: cipher,
      );

      expect(result.isSuccess, isTrue);
      expect(resend.lastHtmlBody, contains('123456'));
    });

    test('fails when secret payload missing (no code emailed)', () async {
      final resend = FakeResendClient();
      final gateway = IamEmailSenderGateway(resendClient: resend);

      final result = await gateway.send(
        templateId: EmailTemplateId.passwordResetCode,
        toEmail: 'lan@gmail.com',
        locale: 'vi',
        refs: const {'operation_id': 'op-1'},
      );

      expect(result.isSuccess, isFalse);
      expect(resend.sendCount, 0);
    });
  });
}
