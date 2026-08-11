import 'i_resend_client.dart';

enum FakeResendScenario {
  sentOk,
  failed,
  rateLimited,
  missingKey,
}

/// Test double for [IResendClient] — no network.
final class FakeResendClient implements IResendClient {
  FakeResendClient({this.scenario = FakeResendScenario.sentOk});

  FakeResendScenario scenario;
  int sendCount = 0;
  String? lastToEmail;
  String? lastSubject;
  String? lastHtmlBody;
  String? lastTextBody;

  @override
  Future<ResendSendResult> send({
    required String toEmail,
    required String subject,
    required String htmlBody,
    required String textBody,
  }) async {
    sendCount++;
    lastToEmail = toEmail;
    lastSubject = subject;
    lastHtmlBody = htmlBody;
    lastTextBody = textBody;
    return switch (scenario) {
      FakeResendScenario.sentOk => ResendSendResult.ok('re_fake_$sendCount'),
      FakeResendScenario.failed => const ResendSendResult.failed('resend_5xx'),
      FakeResendScenario.rateLimited => const ResendSendResult.failed(
        'resend_429_rate_limited',
        rateLimited: true,
      ),
      FakeResendScenario.missingKey => const ResendSendResult.failed(
        'missing_RESEND_API_KEY',
      ),
    };
  }
}
