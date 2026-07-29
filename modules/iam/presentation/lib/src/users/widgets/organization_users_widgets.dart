import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';
import 'invitation_card.dart';
import 'member_card.dart';

/// Tab Button widget dùng trong OrganizationUsersPage.
class OrganizationUsersTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const OrganizationUsersTabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? colors.success : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: VText(
          label,
          variant: VTextVariant.bodyDefault,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Filter Chip widget dùng trong OrganizationUsersPage.
class OrganizationUsersFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<String> onSelect;

  const OrganizationUsersFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space3,
          vertical: VSpacing.space1 + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.successBg : colors.surface,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: isSelected ? colors.success : colors.borderDefault,
          ),
        ),
        child: VText(
          label,
          variant: VTextVariant.bodySmall,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colors.success : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Empty State widget dùng trong OrganizationUsersPage.
class OrganizationUsersEmptyState extends StatelessWidget {
  final VIcons icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final String actionText;
  final Color? actionColor;
  final VoidCallback onAction;

  const OrganizationUsersEmptyState({
    super.key,
    required this.icon,
    this.iconBgColor,
    this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    required this.actionText,
    this.actionColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Align(
      alignment: const Alignment(0, -0.85),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
        child: VCard(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space5,
            vertical: VSpacing.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBgColor ?? colors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: VIcon(
                    icon: icon,
                    size: 28,
                    color: iconColor ?? colors.textSecondary,
                  ),
                ),
              ),
              const VGap.md(),
              VText(
                title,
                variant: VTextVariant.headingH4,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? colors.textPrimary,
                ),
              ),
              const VGap.xs(),
              VText(
                subtitle,
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const VGap.md(),
              GestureDetector(
                onTap: onAction,
                child: VText(
                  actionText,
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: actionColor ?? colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper hiển thị nội dung chính (Members / Invitations / Empty / Error / Unauthorized)
class OrganizationUsersMainContent extends StatelessWidget {
  final bool isUnauthorized;
  final bool hasError;
  final bool isMemberTab;
  final bool isFiltered;
  final List<MemberUiModel> members;
  final List<InvitationUiModel> invitations;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearFilter;
  final VoidCallback onInviteMember;
  final VoidCallback onErrorRetry;
  final ValueChanged<MemberUiModel> onMemberTap;
  final ValueChanged<InvitationUiModel> onInvitationTap;

  const OrganizationUsersMainContent({
    super.key,
    required this.isUnauthorized,
    required this.hasError,
    required this.isMemberTab,
    required this.isFiltered,
    required this.members,
    required this.invitations,
    required this.onRefresh,
    required this.onClearFilter,
    required this.onInviteMember,
    required this.onErrorRetry,
    required this.onMemberTap,
    required this.onInvitationTap,
  });

  Widget _buildScrollableEmptyState(Widget emptyStateWidget) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 480,
          alignment: Alignment.center,
          child: emptyStateWidget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    // Unauthorized / Permission denied state
    if (isUnauthorized) {
      return _buildScrollableEmptyState(
        OrganizationUsersEmptyState(
          icon: VIcons.shield,
          iconBgColor: colors.warningBg,
          iconColor: colors.warning,
          title: 'Bạn không có quyền quản lý',
          subtitle: 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.',
          actionText: 'Quay lại',
          actionColor: colors.success,
          onAction: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
    }

    // Error state
    if (hasError) {
      return _buildScrollableEmptyState(
        OrganizationUsersEmptyState(
          icon: VIcons.close,
          iconBgColor: colors.dangerBg,
          iconColor: colors.danger,
          title: 'Không thể tải danh sách',
          titleColor: colors.danger,
          subtitle: 'Đã xảy ra lỗi khi tải thành viên. Vui lòng thử lại.',
          actionText: 'Thử lại',
          actionColor: colors.danger,
          onAction: onErrorRetry,
        ),
      );
    }

    if (isMemberTab) {
      if (members.isEmpty) {
        if (isFiltered) {
          return _buildScrollableEmptyState(
            OrganizationUsersEmptyState(
              icon: VIcons.search,
              title: 'Không tìm thấy kết quả',
              subtitle: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.',
              actionText: 'Xóa bộ lọc',
              onAction: onClearFilter,
            ),
          );
        }
        return _buildScrollableEmptyState(
          OrganizationUsersEmptyState(
            icon: VIcons.info,
            title: 'Chưa có thành viên khác',
            subtitle: 'Mời thêm người dùng để cùng vận hành tổ chức.',
            actionText: 'Mời thành viên',
            onAction: onInviteMember,
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: VSpacing.screenMobile,
            right: VSpacing.screenMobile,
            bottom: 80,
          ),
          itemCount: members.length,
          separatorBuilder: (_, __) => const VGap.sm(),
          itemBuilder: (context, index) {
            final member = members[index];
            return MemberCard(
              member: member,
              onTap: () => onMemberTap(member),
            );
          },
        ),
      );
    }

    // Invitation tab
    if (invitations.isEmpty) {
      if (isFiltered) {
        return _buildScrollableEmptyState(
          OrganizationUsersEmptyState(
            icon: VIcons.search,
            title: 'Không tìm thấy kết quả',
            subtitle: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.',
            actionText: 'Xóa bộ lọc',
            onAction: onClearFilter,
          ),
        );
      }
      return _buildScrollableEmptyState(
        OrganizationUsersEmptyState(
          icon: VIcons.info,
          title: 'Chưa có lời mời nào',
          subtitle: 'Tạo lời mời mới để thêm người dùng vào tổ chức.',
          actionText: 'Mời thành viên',
          onAction: onInviteMember,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: VSpacing.screenMobile,
          right: VSpacing.screenMobile,
          bottom: 80,
        ),
        itemCount: invitations.length,
        separatorBuilder: (_, __) => const VGap.sm(),
        itemBuilder: (context, index) {
          final invitation = invitations[index];
          return InvitationCard(
            invitation: invitation,
            onTap: () => onInvitationTap(invitation),
          );
        },
      ),
    );
  }
}
