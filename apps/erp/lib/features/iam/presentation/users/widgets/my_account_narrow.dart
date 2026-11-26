import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../views/my_account_page.dart';

/// Bố cục iPhone của Tài khoản của tôi (ID-21).
class MyAccountNarrow extends StatelessWidget {
  const MyAccountNarrow({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onResetPassword,
    required this.onLogout,
    required this.loggingOut,
  });

  final MyAccountUiModel data;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback? onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final initials = VAvatar(name: data.fullName).label;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.screenMobile,
        VSpacing.space4,
        VSpacing.screenMobile,
        34,
      ),
      children: [
        DetailHeaderNarrow(
          leading: DetailAvatar(initials, size: 52),
          title: data.hasName ? data.fullName : '(chưa có tên)',
          subtitle: 'Tài khoản cá nhân',
          badge: data.isOwner
              ? const VBadge(
                  label: 'Chủ sở hữu',
                  tone: VComponentTone.success,
                  variant: VBadgeVariant.soft,
                )
              : null,
          badgeInline: true,
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: VText(
            'Thông tin cá nhân',
            variant: VTextVariant.bodyDefault,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        VCard(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: Column(
            children: [
              _AccountRow(label: 'Họ và tên đệm', value: data.lastName),
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
              _AccountRow(label: 'Tên', value: data.firstName),
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
              _AccountRow(label: 'Email đăng nhập', value: data.email),
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
              _AccountRow(label: 'Trạng thái email', value: data.emailStatus),
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
              _AccountRow(label: 'Số điện thoại', value: data.phoneNumber),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: VText(
            'Thao tác tài khoản',
            variant: VTextVariant.bodyDefault,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        VCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.card),
            child: Column(
              children: [
                _ActionRow(
                  icon: VIcons.edit,
                  title: 'Chỉnh sửa thông tin cá nhân',
                  subtitle: 'Cập nhật hồ sơ cá nhân',
                  onTap: onEdit,
                ),
                Divider(height: 1, thickness: 1, color: colors.borderDefault),
                _ActionRow(
                  icon: VIcons.lock,
                  title: 'Đặt lại mật khẩu',
                  subtitle: 'Xác minh email và tạo mật khẩu mới',
                  onTap: onResetPassword,
                ),
                Divider(height: 1, thickness: 1, color: colors.borderDefault),
                _ActionRow(
                  icon: VIcons.logout,
                  title: 'Đăng xuất',
                  subtitle: 'Kết thúc phiên sử dụng hiện tại',
                  isDanger: true,
                  onTap: loggingOut ? null : onLogout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final trimmed = value.trim();
    final hasValue = trimmed.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VText(
              label,
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: VSpacing.space4),
            Flexible(
              child: VText(
                hasValue ? trimmed : '(chưa có)',
                variant: VTextVariant.bodyDefault,
                color: hasValue ? colors.textPrimary : colors.textMuted,
                style: TextStyle(
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final titleColor = isDanger ? colors.danger : colors.textPrimary;
    final iconColor = isDanger ? colors.danger : colors.textBrand;

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space2,
              ),
              child: Row(
                children: [
                  VIcon(icon: icon, size: 20, color: iconColor),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VText(
                          title,
                          variant: VTextVariant.bodyDefault,
                          color: titleColor,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        VText(
                          subtitle,
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  VIcon(
                    icon: VIcons.chevronRight,
                    size: 18,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
