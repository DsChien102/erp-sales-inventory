import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../views/my_account_page.dart';

/// Bố cục web của Tài khoản của tôi (ID-21): hai cột từ 900, dưới 900 xếp dọc.
class MyAccountWide extends StatelessWidget {
  const MyAccountWide({
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
    final twoColumns = MediaQuery.sizeOf(context).width >= 900;
    final profileCard = _ProfileCard(
      data: data,
      onLogout: onLogout,
      loggingOut: loggingOut,
    );
    final rightColumn = _RightSections(
      data: data,
      onEdit: onEdit,
      onResetPassword: onResetPassword,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.screenDesktop),
      child: twoColumns
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: profileCard),
                const SizedBox(width: VSpacing.space4),
                Expanded(child: rightColumn),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                profileCard,
                const SizedBox(height: VSpacing.space4),
                rightColumn,
              ],
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.data,
    required this.onLogout,
    required this.loggingOut,
  });

  final MyAccountUiModel data;
  final VoidCallback? onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final initials = VAvatar(name: data.fullName).label;

    return FlowCard(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DetailAvatar(initials, size: 72),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: VText(
              data.hasName ? data.fullName : '(chưa có tên)',
              variant: VTextVariant.headingH3,
              color: data.hasName ? colors.textPrimary : colors.textMuted,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          VText(
            data.email,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          if (data.isOwner) ...[
            const SizedBox(height: 8),
            const VBadge(
              label: 'Chủ sở hữu',
              tone: VComponentTone.success,
              variant: VBadgeVariant.soft,
            ),
          ],
          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: colors.borderDefault),
          const SizedBox(height: 16),
          VButton(
            label: 'Đăng xuất',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.danger,
            fullWidth: true,
            isLoading: loggingOut,
            onPressed: loggingOut ? null : onLogout,
          ),
        ],
      ),
    );
  }
}

class _RightSections extends StatelessWidget {
  const _RightSections({
    required this.data,
    required this.onEdit,
    required this.onResetPassword,
  });

  final MyAccountUiModel data;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;

  /// Prototype `.t1-acrow`: đệm dọc 8; rỗng → "(chưa có)" mờ, chữ thường.
  Widget _row(String label, String value) {
    final trimmed = value.trim();
    final hasValue = trimmed.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
      child: DetailRow(
        label: label,
        value: hasValue ? trimmed : '(chưa có)',
        valueMuted: !hasValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailSectionWide(
          title: 'Thông tin cá nhân',
          gap: 4,
          action: IconButton(
            tooltip: 'Chỉnh sửa thông tin cá nhân',
            icon: VIcon(
              icon: VIcons.edit,
              size: 20,
              color: colors.textSecondary,
            ),
            onPressed: onEdit,
          ),
          children: [
            _row('Họ và tên đệm', data.lastName),
            _row('Tên', data.firstName),
            _row('Email đăng nhập', data.email),
            _row('Trạng thái email', data.emailStatus),
            _row('Số điện thoại', data.phoneNumber),
          ],
        ),
        const SizedBox(height: VSpacing.space4),
        DetailSectionWide(
          title: 'Bảo mật',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Đặt lại mật khẩu',
                        variant: VTextVariant.bodyDefault,
                        color: colors.textPrimary,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      VText(
                        'Xác minh email và tạo mật khẩu mới',
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                VButton(
                  label: 'Đặt lại mật khẩu',
                  variant: VButtonVariant.secondary,
                  onPressed: onResetPassword,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
