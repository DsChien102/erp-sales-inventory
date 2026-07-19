import 'package:test/test.dart';
import 'package:vet45_resend/vet45_resend.dart';

void main() {
  group('ResendEmailClient', () {
    test('soft-fails when API key is missing', () async {
      final client = ResendEmailClient(apiKey: null);
      final result = await client.send(
        toEmail: 'a@b.c',
        subject: 's',
        htmlBody: '<p>h</p>',
        textBody: 't',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, 'missing_RESEND_API_KEY');
    });

    test('soft-fails when API key is empty', () async {
      final client = ResendEmailClient(apiKey: '');
      final result = await client.send(
        toEmail: 'a@b.c',
        subject: 's',
        htmlBody: '<p>h</p>',
        textBody: 't',
      );
      expect(result.error, 'missing_RESEND_API_KEY');
    });
  });

  group('FakeResendClient', () {
    test('sentOk returns message id', () async {
      final client = FakeResendClient();
      final result = await client.send(
        toEmail: 'a@b.c',
        subject: 's',
        htmlBody: '<p>h</p>',
        textBody: 't',
      );
      expect(result.isSuccess, isTrue);
      expect(result.messageId, 're_fake_1');
      expect(client.sendCount, 1);
      expect(client.lastToEmail, 'a@b.c');
    });

    test('failed and rateLimited scenarios', () async {
      final client = FakeResendClient(scenario: FakeResendScenario.failed);
      var result = await client.send(
        toEmail: 'a@b.c',
        subject: 's',
        htmlBody: '<p>h</p>',
        textBody: 't',
      );
      expect(result.error, 'resend_5xx');

      client.scenario = FakeResendScenario.rateLimited;
      result = await client.send(
        toEmail: 'a@b.c',
        subject: 's',
        htmlBody: '<p>h</p>',
        textBody: 't',
      );
      expect(result.rateLimited, isTrue);
      expect(result.error, 'resend_429_rate_limited');
    });
  });
}
