import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../data/models/tenant_audit_log.dart';

/// Single event catalog entry with Vietnamese title, icon, category and search aliases.
final class TenantAuditEventCatalogEntry {
  const TenantAuditEventCatalogEntry({
    required this.eventCode,
    required this.title,
    required this.category,
    required this.icon,
    this.searchAliases = const [],
  });

  final String eventCode;
  final String title;
  final TenantAuditEventCategory category;
  final VIcons icon;
  final List<String> searchAliases;
}

/// Single source of truth for IAM audit event display and metadata in Presentation.
abstract final class TenantAuditEventCatalog {
  static const Map<String, TenantAuditEventCatalogEntry> _entries = {
    // 1. Member
    IamAuditEvents.membershipDeactivated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.membershipDeactivated,
      title: 'Tạm ngừng thành viên',
      category: TenantAuditEventCategory.member,
      icon: VIcons.warning,
      searchAliases: ['tạm dừng', 'deactivate member', 'ngừng hoạt động'],
    ),
    IamAuditEvents.membershipReactivated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.membershipReactivated,
      title: 'Kích hoạt lại thành viên',
      category: TenantAuditEventCategory.member,
      icon: VIcons.shield,
      searchAliases: ['kích hoạt lại', 'reactivate member', 'mở lại'],
    ),
    IamAuditEvents.membershipRemoved: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.membershipRemoved,
      title: 'Loại thành viên khỏi tổ chức',
      category: TenantAuditEventCategory.member,
      icon: VIcons.delete,
      searchAliases: ['xóa thành viên', 'remove member', 'loại bỏ'],
    ),
    IamAuditEvents.tenantOwnerActivated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.tenantOwnerActivated,
      title: 'Kích hoạt tài khoản chủ sở hữu',
      category: TenantAuditEventCategory.member,
      icon: VIcons.personCheck,
      searchAliases: ['kích hoạt owner', 'activate owner'],
    ),

    // 2. Role
    IamAuditEvents.memberRoleAssigned: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.memberRoleAssigned,
      title: 'Phân vai trò thành viên',
      category: TenantAuditEventCategory.role,
      icon: VIcons.people,
      searchAliases: ['gán vai trò', 'đổi vai trò', 'assign role'],
    ),
    'iam.membership.role_changed': TenantAuditEventCatalogEntry(
      eventCode: 'iam.membership.role_changed',
      title: 'Thay đổi vai trò thành viên',
      category: TenantAuditEventCategory.role,
      icon: VIcons.people,
      searchAliases: ['thay đổi vai trò', 'change role'],
    ),

    // 3. Organization
    IamAuditEvents.tenantProfileUpdated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.tenantProfileUpdated,
      title: 'Cập nhật hồ sơ tổ chức',
      category: TenantAuditEventCategory.organization,
      icon: VIcons.apartment,
      searchAliases: ['sửa hồ sơ', 'update profile', 'thông tin tổ chức'],
    ),
    IamAuditEvents.tenantLegalProfileUpdated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.tenantLegalProfileUpdated,
      title: 'Cập nhật hồ sơ pháp lý',
      category: TenantAuditEventCategory.organization,
      icon: VIcons.description,
      searchAliases: ['hồ sơ pháp lý', 'mã số thuế', 'legal profile'],
    ),
    IamAuditEvents.tenantActivated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.tenantActivated,
      title: 'Kích hoạt tổ chức',
      category: TenantAuditEventCategory.organization,
      icon: VIcons.success,
      searchAliases: ['mở tổ chức', 'activate tenant'],
    ),
    IamAuditEvents.tenantSuspended: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.tenantSuspended,
      title: 'Tạm ngừng tổ chức',
      category: TenantAuditEventCategory.organization,
      icon: VIcons.warning,
      searchAliases: ['khóa tổ chức', 'suspend tenant'],
    ),
    IamAuditEvents.tenantRestored: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.tenantRestored,
      title: 'Khôi phục tổ chức',
      category: TenantAuditEventCategory.organization,
      icon: VIcons.restore,
      searchAliases: ['mở lại tổ chức', 'restore tenant'],
    ),
    IamAuditEvents.tenantOwnershipTransferred: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.tenantOwnershipTransferred,
      title: 'Chuyển chủ sở hữu tổ chức',
      category: TenantAuditEventCategory.organization,
      icon: VIcons.personCheck,
      searchAliases: ['chuyển quyền', 'transfer ownership'],
    ),

    // 4. Invitation
    IamAuditEvents.invitationCreated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.invitationCreated,
      title: 'Tạo lời mời thành viên',
      category: TenantAuditEventCategory.invitation,
      icon: VIcons.mail,
      searchAliases: ['mời thành viên', 'create invitation'],
    ),
    IamAuditEvents.invitationResent: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.invitationResent,
      title: 'Gửi lại lời mời thành viên',
      category: TenantAuditEventCategory.invitation,
      icon: VIcons.send,
      searchAliases: ['gửi lại lời mời', 'resend invitation'],
    ),
    IamAuditEvents.invitationRevoked: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.invitationRevoked,
      title: 'Thu hồi lời mời thành viên',
      category: TenantAuditEventCategory.invitation,
      icon: VIcons.close,
      searchAliases: ['hủy lời mời', 'revoke invitation'],
    ),
    IamAuditEvents.invitationAccepted: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.invitationAccepted,
      title: 'Chấp nhận lời mời tham gia',
      category: TenantAuditEventCategory.invitation,
      icon: VIcons.success,
      searchAliases: ['nhận lời mời', 'accept invitation'],
    ),

    // 5. Account
    IamAuditEvents.accountProfileUpdated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.accountProfileUpdated,
      title: 'Cập nhật thông tin tài khoản',
      category: TenantAuditEventCategory.account,
      icon: VIcons.person,
      searchAliases: ['sửa tài khoản', 'account profile'],
    ),
    IamAuditEvents.userProfileUpdated: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.userProfileUpdated,
      title: 'Cập nhật thông tin người dùng',
      category: TenantAuditEventCategory.account,
      icon: VIcons.person,
      searchAliases: ['sửa người dùng', 'user profile'],
    ),

    // 6. Security
    IamAuditEvents.accountPasswordResetCompleted: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.accountPasswordResetCompleted,
      title: 'Đặt lại mật khẩu thành công',
      category: TenantAuditEventCategory.security,
      icon: VIcons.lock,
      searchAliases: ['đổi mật khẩu', 'reset password'],
    ),
    IamAuditEvents.accountSignedOut: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.accountSignedOut,
      title: 'Đăng xuất khỏi hệ thống',
      category: TenantAuditEventCategory.security,
      icon: VIcons.logout,
      searchAliases: ['đăng xuất', 'sign out'],
    ),
  };

  /// Returns catalog entry for event code or a neutral fallback entry.
  static TenantAuditEventCatalogEntry entryFor(String eventCode) {
    final entry = _entries[eventCode];
    if (entry != null) return entry;

    return TenantAuditEventCatalogEntry(
      eventCode: eventCode,
      title: 'Hoạt động quản trị',
      category: TenantAuditEventCategory.system,
      icon: VIcons.history,
    );
  }

  /// Finds event codes only for complete localized titles or aliases.
  static List<String> matchingEventCodes(String search) {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final matched = <String>[];
    for (final entry in _entries.values) {
      if (entry.title.toLowerCase() == query ||
          entry.searchAliases.any((alias) => alias.toLowerCase() == query)) {
        matched.add(entry.eventCode);
      }
    }
    return matched;
  }

  /// Returns all event codes belonging to a category.
  static List<String> codesForCategory(TenantAuditEventCategory category) {
    return _entries.values
        .where((e) => e.category == category)
        .map((e) => e.eventCode)
        .toList(growable: false);
  }
}
