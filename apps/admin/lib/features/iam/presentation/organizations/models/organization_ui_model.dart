import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Enum đại diện cho các trạng thái của Tổ chức.
enum OrganizationStatus {
  all('Tất cả'),
  settingUp('Đang thiết lập'),
  active('Đang hoạt động'),
  suspended('Đã tạm ngừng'),
  closed('Đã đóng');

  const OrganizationStatus(this.label);
  final String label;
}

/// Dynamic styling extension cho [OrganizationStatus]
extension OrganizationStatusX on OrganizationStatus {
  String get filterLabel => switch (this) {
        OrganizationStatus.all => 'Tất cả',
        OrganizationStatus.settingUp => 'Thiết lập',
        OrganizationStatus.active => 'Hoạt động',
        OrganizationStatus.suspended => 'Tạm ngừng',
        OrganizationStatus.closed => 'Đã đóng',
      };

  VComponentTone get tone => switch (this) {
        OrganizationStatus.settingUp => VComponentTone.warning,
        OrganizationStatus.active => VComponentTone.success,
        OrganizationStatus.suspended => VComponentTone.danger,
        OrganizationStatus.closed => VComponentTone.neutral,
        OrganizationStatus.all => VComponentTone.primary,
      };

  Color getBadgeBackgroundColor(VColorScheme colors) => switch (this) {
        OrganizationStatus.settingUp => colors.warningBg,
        OrganizationStatus.active => colors.successBg,
        OrganizationStatus.suspended => colors.dangerBg,
        OrganizationStatus.closed => const Color(0xFFFDE8E8), // soft danger/pink bg for PA-D-05
        OrganizationStatus.all => colors.primary,
      };

  Color getBadgeTextColor(VColorScheme colors) => switch (this) {
        OrganizationStatus.settingUp => colors.warning,
        OrganizationStatus.active => colors.success,
        OrganizationStatus.suspended => colors.danger,
        OrganizationStatus.closed => colors.danger, // red text for PA-D-05
        OrganizationStatus.all => colors.primary,
      };
}

/// Model cho thành viên thuộc tổ chức.
class OrganizationMemberUiModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarInitials;
  final bool isOwner;

  const OrganizationMemberUiModel({
    required this.id,
    required this.name,
    this.email = '',
    this.role = 'Thành viên tổ chức',
    this.avatarInitials,
    this.isOwner = false,
  });

  String get resolvedInitials {
    if (avatarInitials != null && avatarInitials!.isNotEmpty) {
      return avatarInitials!;
    }
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0].substring(0, words[0].length.clamp(1, 2)).toUpperCase();
    }
    return 'NV';
  }
}

/// Data model UI đại diện cho một tổ chức trên giao diện danh sách & chi tiết.
class OrganizationUiModel {
  final String id;
  final String name;
  final String code;
  final String type;
  final OrganizationStatus status;
  final String? initials;
  final String? ownerUserId;
  final String? ownerName;
  final String? ownerEmail;
  final String ownerRole;
  final bool unverifiedEmail;
  final bool incompleteProfile;
  final List<OrganizationMemberUiModel> members;
  final DateTime? createdAt;
  final DateTime? activatedAt;
  final DateTime? lastActiveAt;
  final String? dataVersion;
  final DateTime? suspendedAt;
  final String? suspendedBy;
  final String? suspendReason;
  final DateTime? closedAt;
  final String? closedBy;
  final String? closeReason;

  const OrganizationUiModel({
    required this.id,
    required this.name,
    required this.code,
    this.type = 'Tổ chức nền tảng',
    required this.status,
    this.initials,
    this.ownerUserId,
    this.ownerName,
    this.ownerEmail,
    this.ownerRole = 'Chủ cửa hàng',
    this.unverifiedEmail = false,
    this.incompleteProfile = false,
    this.members = const [],
    this.createdAt,
    this.activatedAt,
    this.lastActiveAt,
    this.dataVersion,
    this.suspendedAt,
    this.suspendedBy,
    this.suspendReason,
    this.closedAt,
    this.closedBy,
    this.closeReason,
  });

  /// Active members eligible as new owner (excludes current owner).
  List<OrganizationMemberUiModel> get transferOwnershipCandidates {
    return members
        .where((m) {
          if (m.isOwner) return false;
          final ownerId = ownerUserId;
          if (ownerId != null && ownerId.isNotEmpty && m.id == ownerId) {
            return false;
          }
          return true;
        })
        .toList();
  }

  int get memberCount => members.isNotEmpty ? members.length : 1;

  /// Helper lấy chuỗi 2 chữ cái đầu nếu [initials] chưa có.
  String get resolvedInitials {
    if (initials != null && initials!.isNotEmpty) return initials!;
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0].substring(0, words[0].length.clamp(1, 2)).toUpperCase();
    }
    return 'TC';
  }
}
