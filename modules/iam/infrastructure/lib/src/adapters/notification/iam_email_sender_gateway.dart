import 'package:vet45_iam_application/application.dart';
import 'package:vet45_resend/vet45_resend.dart';

import 'email_template_renderer.dart';

/// Renders templates and sends via Resend.
///
/// For [EmailTemplateId.passwordResetCode]: fetches plaintext code via
/// [IPasswordResetCodeGateway] using `refs['operation_id']` before rendering.
/// If peek returns null (expired/completed), send is skipped and a failure
/// result is returned so the worker marks the outcome failed.
final class IamEmailSenderGateway implements IEmailSenderGateway {
  IamEmailSenderGateway({
    required IResendClient resendClient,
    required IPasswordResetCodeGateway codeGateway,
  }) : _resend = resendClient,
       _codeGateway = codeGateway;

  final IResendClient _resend;
  final IPasswordResetCodeGateway _codeGateway;

  @override
  Future<EmailSendResult> send({
    required EmailTemplateId templateId,
    required String toEmail,
    required String locale,
    required Map<String, String> refs,
    String? appLinkUrl,
  }) async {
    String? code;
    if (templateId == EmailTemplateId.passwordResetCode) {
      final operationId = refs['operation_id'];
      if (operationId == null) {
        return const EmailSendResult(
          isSuccess: false,
          error: 'password_reset_code: missing refs.operation_id',
        );
      }
      code = await _codeGateway.peekDeliveryCode(operationId);
      if (code == null) {
        return const EmailSendResult(
          isSuccess: false,
          error: 'password_reset_code: operation expired or completed',
        );
      }
    }

    final rendered = EmailTemplateRenderer.render(
      templateId: templateId,
      toEmail: toEmail,
      locale: locale,
      refs: refs,
      appLinkUrl: appLinkUrl,
      code: code,
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
