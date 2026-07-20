import 'package:vet45_iam_application/application.dart';

/// Builds stub subject/body for the four Theme 1 email templates.
abstract final class EmailTemplateRenderer {
  static ({String subject, String html, String text}) render({
    required EmailTemplateId templateId,
    required String toEmail,
    required String locale,
    required Map<String, String> refs,
    String? appLinkUrl,
  }) {
    final link = appLinkUrl ?? '';
    final refNote = refs.isEmpty ? '' : ' refs=${refs.keys.join(",")}';
    switch (templateId) {
      case EmailTemplateId.activationInvitation:
        return (
          subject: 'Kích hoạt tài khoản VET45',
          html:
              '<p>Xin chào,</p><p>Hãy kích hoạt tài khoản VET45.</p>'
              '${link.isEmpty ? '' : '<p><a href="$link">Mở ứng dụng</a></p>'}',
          text: 'Kích hoạt tài khoản VET45 ($locale). $link$refNote',
        );
      case EmailTemplateId.tenantInvitation:
        return (
          subject: 'Lời mời tham gia tổ chức trên VET45',
          html:
              '<p>Bạn được mời tham gia một tổ chức trên VET45.</p>'
              '${link.isEmpty ? '' : '<p><a href="$link">Mở lời mời</a></p>'}',
          text: 'Lời mời tham gia tổ chức VET45 ($locale) → $toEmail. $link$refNote',
        );
      case EmailTemplateId.passwordResetCode:
        return (
          subject: 'Mã đặt lại mật khẩu VET45',
          html:
              '<p>Nhập mã xác nhận trong ứng dụng để đặt lại mật khẩu.</p>'
              '<p>Mã không được gửi trong email template stub (Identity owns code).</p>',
          text: 'Đặt lại mật khẩu VET45 — nhập mã trong ứng dụng ($locale).',
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
