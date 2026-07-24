import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'edit_my_account_page.dart';
import 'reset_password_page.dart';

/// Model thông tin cá nhân tài khoản người dùng (TA-D-01).
class MyAccountUiModel {
  final String firstName;
  final String lastName;
  final String email;
  final String emailStatus;
  final String phoneNumber;

  const MyAccountUiModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emailStatus,
    required this.phoneNumber,
  });

  String get fullName => '$firstName $lastName'.trim();

  static const sample = MyAccountUiModel(
    firstName: 'Nguyễn Văn',
    lastName: 'Minh',
    email: 'minh@gmail.com',
    emailStatus: 'Đã xác minh',
    phoneNumber: '0901 234 567',
  );
}

/// Trang Tài khoản của tôi (TA-D-01).
class MyAccountPage extends StatefulWidget {
  final MyAccountUiModel data;
  final VoidCallback? onLogout;

  const MyAccountPage({
    super.key,
    this.data = MyAccountUiModel.sample,
    this.onLogout,
  });

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool _isActionsOpen = false;
  late MyAccountUiModel _accountData;

  @override
  void initState() {
    super.initState();
    _accountData = widget.data;
  }

  void _showLogoutConfirmation() {
    showVBottomSheet<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VText(
              'Đăng xuất khỏi VET45?',
              variant: VTextVariant.headingH3,
              color: context.vColors.danger,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.xs(),
            VText(
              'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.',
              variant: VTextVariant.bodySmall,
              color: context.vColors.textSecondary,
            ),
            const VGap.xl(),
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const VGap.md(),
            VButton(
              label: 'Đăng xuất',
              variant: VButtonVariant.dangerOutline,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onLogout?.call();
              },
            ),
            const VGap.md(),
          ],
        ),
      ),
    );
  }

  void _showActionsBottomSheet() {
    setState(() {
      _isActionsOpen = true;
    });

    showVBottomSheet<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VText(
              'Thao tác tài khoản',
              variant: VTextVariant.headingH3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.md(),
            VCard(
              onTap: () async {
                Navigator.of(context).pop();
                final updated = await Navigator.of(context).push<MyAccountUiModel>(
                  MaterialPageRoute(
                    builder: (context) => EditMyAccountPage(data: _accountData),
                  ),
                );

                if (updated != null && mounted) {
                  setState(() {
                    _accountData = updated;
                  });
                  VToast.show(
                    context,
                    title: 'Thành công',
                    message: 'Đã cập nhật thông tin cá nhân',
                    type: VToastType.success,
                  );
                }
              },
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Row(
                children: [
                  VIcon(
                    icon: VIcons.edit,
                    size: 20,
                    color: context.vColors.textPrimary,
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          'Chỉnh sửa thông tin cá nhân',
                          variant: VTextVariant.bodyDefault,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const VGap.xs(),
                        VText(
                          'Cập nhật hồ sơ cá nhân',
                          variant: VTextVariant.bodySmall,
                          color: context.vColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  VIcon(
                    icon: VIcons.chevronRight,
                    size: 20,
                    color: context.vColors.textSecondary,
                  ),
                ],
              ),
            ),
            const VGap.sm(),
            VCard(
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const ResetPasswordPage(),
                  ),
                );

                if (result == true && mounted) {
                  VToast.show(
                    context,
                    title: 'Thành công',
                    message: 'Đã đặt lại mật khẩu.',
                    type: VToastType.success,
                  );
                }
              },
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Row(
                children: [
                  VIcon(
                    icon: VIcons.lock,
                    size: 20,
                    color: context.vColors.textPrimary,
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          'Đặt lại mật khẩu',
                          variant: VTextVariant.bodyDefault,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const VGap.xs(),
                        VText(
                          'Xác minh email và tạo mật khẩu mới',
                          variant: VTextVariant.bodySmall,
                          color: context.vColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  VIcon(
                    icon: VIcons.chevronRight,
                    size: 20,
                    color: context.vColors.textSecondary,
                  ),
                ],
              ),
            ),
            const VGap.sm(),
            Container(
              decoration: BoxDecoration(
                color: context.vColors.dangerBg,
                borderRadius: BorderRadius.circular(VRadius.card),
                border: Border.all(color: context.vColors.danger),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showLogoutConfirmation();
                  },
                  borderRadius: BorderRadius.circular(VRadius.card),
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Row(
                      children: [
                        VIcon(
                          icon: VIcons.logout,
                          size: 20,
                          color: context.vColors.danger,
                        ),
                        const SizedBox(width: VSpacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VText(
                                'Đăng xuất',
                                variant: VTextVariant.bodyDefault,
                                color: context.vColors.danger,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const VGap.xs(),
                              VText(
                                'Kết thúc phiên sử dụng hiện tại',
                                variant: VTextVariant.bodySmall,
                                color: context.vColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        VIcon(
                          icon: VIcons.chevronRight,
                          size: 20,
                          color: context.vColors.danger,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VGap.lg(),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isActionsOpen = false;
        });
      }
    });
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VText(
            label,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.horizontalSm(),
          Flexible(
            child: VText(
              value,
              variant: VTextVariant.bodyDefault,
              style: const TextStyle(fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final data = _accountData;

    return VPageScaffold(
      title: 'Tài khoản của tôi',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        children: [
          // Card 1 — Tóm tắt danh tính cá nhân (không click)
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIconBox(
                  icon: VIcons.person,
                  size: 40,
                  iconSize: 20,
                  backgroundColor: colors.surfaceAlt,
                  iconColor: colors.textPrimary,
                  borderRadius: VRadius.r12,
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        data.fullName,
                        variant: VTextVariant.headingH4,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const VGap.xs(),
                      VText(
                        'Tài khoản cá nhân',
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VGap.md(),

          // Card 2 — Thông tin cá nhân
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Thông tin cá nhân',
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.md(),
                _buildInfoRow(context, 'Họ và tên đệm', data.firstName),
                _buildInfoRow(context, 'Tên', data.lastName),
                _buildInfoRow(context, 'Email đăng nhập', data.email),
                _buildInfoRow(context, 'Trạng thái email', data.emailStatus),
                _buildInfoRow(context, 'Số điện thoại', data.phoneNumber),
              ],
            ),
          ),
          const VGap.xl(),
        ],
      ),
      bottomBar: Container(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.borderDefault),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: VButton(
              label: 'Thao tác',
              variant: VButtonVariant.primary,
              tone: VComponentTone.primary,
              fullWidth: true,
              trailingIcon: VIcon(
                icon: _isActionsOpen ? VIcons.chevronDown : VIcons.chevronUp,
                color: VColors.neutral0,
                size: 18,
              ),
              onPressed: _showActionsBottomSheet,
            ),
          ),
        ),
      ),
    );
  }
}
