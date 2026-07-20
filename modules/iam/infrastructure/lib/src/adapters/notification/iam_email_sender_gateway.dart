import 'package:vet45_iam_application/application.dart';
import 'package:vet45_resend/vet45_resend.dart';

import 'email_template_renderer.dart';

/// Renders template stubs and sends via Resend.
final class IamEmailSenderGateway implements IEmailSenderGateway {
  IamEmailSenderGateway({required IResendClient resendClient})
    : _resend = resendClient;

  final IResendClient _resend;

  @override
  Future<EmailSendResult> send({
    required EmailTemplateId templateId,
    required String toEmail,
    required String locale,
    required Map<String, String> refs,
    String? appLinkUrl,
  }) async {
    final rendered = EmailTemplateRenderer.render(
      templateId: templateId,
      toEmail: toEmail,
      locale: locale,
      refs: refs,
      appLinkUrl: appLinkUrl,
    );

    final result = await _resend.send(
      toEmail: toEmail,
      subject: rendered.subject,
      htmlBody: rendered.html,
      textBody: rendered.text,
    );

    return EmailSendResult(
      isSuccess: result.isSuccess,
      messageId: result.messageId,
      error: result.error,
    );
  }
}
