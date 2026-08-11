import 'dart:convert';

import 'package:vet45_iam_application/application.dart';
import 'package:vet45_resend/vet45_resend.dart';

import 'email_template_renderer.dart';

/// Renders templates and sends via Resend.
///
/// For [EmailTemplateId.passwordResetCode], [EmailTemplateId.tenantInvitation],
/// and [EmailTemplateId.activationInvitation]: decodes the raw code/token from
/// the transient `secret_payload_ciphertext` channel (key outside DB). If it is
/// absent or malformed, send is skipped and a failure result is returned — an
/// email without its code is useless to the recipient, so the worker marks the
/// outcome failed instead of delivering it.
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
    String? secretPayloadCiphertext,
  }) async {
    String? code;
    if (templateId == EmailTemplateId.activationInvitation) {
      code = _decodeTransientSecret(secretPayloadCiphertext);
      if (code == null) {
        return const EmailSendResult(
          isSuccess: false,
          error: 'activation_invitation: missing or malformed secret payload',
        );
      }
    }
    if (templateId == EmailTemplateId.tenantInvitation) {
      code = _decodeTransientSecret(secretPayloadCiphertext);
      if (code == null) {
        return const EmailSendResult(
          isSuccess: false,
          error: 'tenant_invitation: missing or malformed secret payload',
        );
      }
    }
    if (templateId == EmailTemplateId.passwordResetCode) {
      code = _decodeTransientSecret(secretPayloadCiphertext);
      if (code == null) {
        return const EmailSendResult(
          isSuccess: false,
          error: 'password_reset_code: missing or malformed secret payload',
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

  /// Transient stand-in envelope written by the mutation RPC:
  /// `transient:` + base64(UTF-8 raw token). Returns null when absent or
  /// undecodable so the caller can fail the delivery instead of sending an
  /// email with no code in it.
  static String? _decodeTransientSecret(String? ciphertext) {
    const prefix = 'transient:';
    if (ciphertext == null || !ciphertext.startsWith(prefix)) {
      return null;
    }
    final encoded = ciphertext.substring(prefix.length);
    if (encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = utf8.decode(base64.decode(encoded));
      return decoded.isEmpty ? null : decoded;
    } on FormatException {
      return null;
    }
  }
}
