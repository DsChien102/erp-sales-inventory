import 'package:vet45_iam_application/application.dart';

/// Builds subject/body for the four Theme 1 email templates.
///
/// For [EmailTemplateId.passwordResetCode] pass the plaintext [code] fetched
/// via [IPasswordResetCodeGateway]. If [code] is null the render still
/// succeeds but omits the code block (should not happen in production).
abstract final class EmailTemplateRenderer {
  static ({String subject, String html, String text}) render({
    required EmailTemplateId templateId,
    required String toEmail,
    required String locale,
    required Map<String, String> refs,
    String? appLinkUrl,
    String? code,
  }) {
    final link = appLinkUrl ?? '';
    switch (templateId) {
      case EmailTemplateId.activationInvitation:
        return (
          subject: 'Kích hoạt tài khoản VET45',
          html:
              '<p>Xin chào,</p><p>Hãy kích hoạt tài khoản VET45.</p>'
              '${link.isEmpty ? '' : '<p><a href="$link">Mở ứng dụng</a></p>'}',
          text: 'Kích hoạt tài khoản VET45 ($locale). $link',
        );
      case EmailTemplateId.tenantInvitation:
        return (
          subject: 'Lời mời tham gia tổ chức trên VET45',
          html:
              '<p>Bạn được mời tham gia một tổ chức trên VET45.</p>'
              '${link.isEmpty ? '' : '<p><a href="$link">Mở lời mời</a></p>'}',
          text: 'Lời mời tham gia tổ chức VET45 ($locale) → $toEmail. $link',
        );
      case EmailTemplateId.passwordResetCode:
        final codeBlock = code != null
            ? '<p style="font-size:2rem;letter-spacing:.5rem;font-weight:bold">$code</p>'
            : '';
        final codeText = code != null ? 'Mã: $code — ' : '';
        return (
          subject: 'Mã đặt lại mật khẩu VET45',
          html:
              '<p>Nhập mã xác nhận trong ứng dụng để đặt lại mật khẩu.</p>'
              '$codeBlock',
          text: '${codeText}Đặt lại mật khẩu VET45 — nhập mã trong ứng dụng ($locale).',
        );
      case EmailTemplateId.securityNotification:
        return (
          subject: 'Thông báo bảo mật VET45',
          html: '<p>Thông báo bảo mật tài khoản VET45.</p>',
          text: 'Thông báo bảo mật VET45 ($locale) → $toEmail.',
        );
    }
  }
}
