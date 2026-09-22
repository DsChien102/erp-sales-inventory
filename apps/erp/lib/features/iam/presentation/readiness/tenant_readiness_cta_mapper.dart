import 'package:vet45_iam_application/application.dart';

/// Maps readiness issue codes to in-app repair routes (S11).
abstract final class TenantReadinessCtaMapper {
  static String? routeFor(String issueCode) {
    switch (issueCode) {
      case TenantReadinessIssueCodes.displayNameMissing:
      case TenantReadinessIssueCodes.contactEmailMissingOrInvalid:
      case TenantReadinessIssueCodes.contactPhoneMissingOrInvalid:
      case TenantReadinessIssueCodes.contactAddressMissing:
        return '/more/organization-profile/edit';
      case TenantReadinessIssueCodes.legalProfileMissing:
      case TenantReadinessIssueCodes.duplicateTaxCode:
        return '/more/organization-profile/legal';
      default:
        return null;
    }
  }

  static String labelFor(String issueCode) {
    return switch (issueCode) {
      TenantReadinessIssueCodes.displayNameMissing => 'Thiếu tên hiển thị tổ chức',
      TenantReadinessIssueCodes.contactEmailMissingOrInvalid =>
        'Email liên hệ thiếu hoặc không hợp lệ',
      TenantReadinessIssueCodes.contactPhoneMissingOrInvalid =>
        'Số điện thoại thiếu hoặc không hợp lệ',
      TenantReadinessIssueCodes.contactAddressMissing => 'Thiếu địa chỉ liên hệ',
      TenantReadinessIssueCodes.legalProfileMissing => 'Chưa có hồ sơ pháp lý',
      TenantReadinessIssueCodes.duplicateTaxCode => 'Mã số thuế trùng với hồ sơ khác',
      TenantReadinessIssueCodes.ownerMembershipInvalid => 'Membership chủ sở hữu không hợp lệ',
      TenantReadinessIssueCodes.ownerAcceptancePending => 'Đang chờ chủ sở hữu chấp nhận lời mời',
      TenantReadinessIssueCodes.ownerInvitationExpired => 'Lời mời hết hạn',
      TenantReadinessIssueCodes.ownerRoleInvalid => 'Vai trò chủ sở hữu không hợp lệ',
      TenantReadinessIssueCodes.ownerIdentityInactive =>
        'Danh tính chủ sở hữu đang không hoạt động',
      TenantReadinessIssueCodes.ownerIdentityUnavailable =>
        'Không xác định được danh tính chủ sở hữu',
      TenantReadinessIssueCodes.ownerEmailUnverified => 'Email chủ sở hữu chưa được xác minh',
      TenantReadinessIssueCodes.platformBlockerPresent => 'Có chặn từ nền tảng — liên hệ hỗ trợ',
      _ => issueCode,
    };
  }

  static String supportHintFor(String issueCode) {
    return 'Liên hệ quản trị viên nền tảng để xử lý điều kiện này.';
  }
}
