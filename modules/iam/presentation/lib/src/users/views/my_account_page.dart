import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/logout_confirmation_bottom_sheet.dart';
import '../widgets/my_account_actions_bottom_sheet.dart';
import 'edit_my_account_page.dart';
import 'reset_password_page.dart';

/// Model thông tin cá nhân tài khoản người dùng (TA-D-01).
class MyAccountUiModel {
  final String firstName;
  final String lastName;
  final String email;
  final String emailStatus;
  final String phoneNumber;
  final String? avatarUrl;

  const MyAccountUiModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emailStatus,
    required this.phoneNumber,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get hasName => fullName.isNotEmpty;

  factory MyAccountUiModel.fromDto(MyIdentityProfileDto dto) {
    return MyAccountUiModel(
      firstName: dto.firstName,
      lastName: dto.lastName,
      email: dto.email,
      emailStatus: dto.emailVerified ? 'Đã xác minh' : 'Chưa xác minh',
      phoneNumber: dto.phoneNumber ?? '',
      avatarUrl: dto.avatarUrl,
    );
  }

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
  final IIamModule? iamModule;

  const MyAccountPage({
    super.key,
    this.data = MyAccountUiModel.sample,
    this.onLogout,
    this.iamModule,
  });

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool _isActionsOpen = false;
  late MyAccountUiModel _accountData;
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _accountData = widget.data;
    if (widget.iamModule != null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final module = widget.iamModule;
    if (module == null) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final dto = await module.executeQueryAsync<MyIdentityProfileDto>(
        GetMyIdentityProfileQuery(),
      );
      if (!mounted) return;
      setState(() {
        _accountData = MyAccountUiModel.fromDto(dto);
        _isLoading = false;
      });
    } on ApplicationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  void _showLogoutConfirmation() {
    showLogoutConfirmationBottomSheet(
      context: context,
      onConfirm: () => widget.onLogout?.call(),
    );
  }

  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return '***';
    final local = email.substring(0, at);
    final domain = email.substring(at);
    if (local.length <= 2) return '${local[0]}***$domain';
    return '${local.substring(0, 2)}***$domain';
  }

  void _showActionsBottomSheet() {
    setState(() => _isActionsOpen = true);

    showMyAccountActionsBottomSheet(
      context: context,
      onEditProfile: () async {
        final updated = await Navigator.of(context).push<MyAccountUiModel>(
          MaterialPageRoute(
            builder: (context) => EditMyAccountPage(
              data: _accountData,
              iamModule: widget.iamModule,
            ),
          ),
        );

        if (updated != null && mounted) {
          setState(() => _accountData = updated);
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã cập nhật thông tin cá nhân',
            type: VToastType.success,
          );
        }
      },
      onResetPassword: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(
              email: _accountData.email,
              iamModule: widget.iamModule,
            ),
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
      onLogout: _showLogoutConfirmation,
    ).then((_) {
      if (mounted) {
        setState(() => _isActionsOpen = false);
      }
    });
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    final colors = context.vColors;
    final hasValue = value != null && value.trim().isNotEmpty;
    final displayValue = hasValue ? value.trim() : '(chưa có)';

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
              displayValue,
              variant: VTextVariant.bodyDefault,
              color: hasValue ? null : colors.textMuted,
              style: TextStyle(fontWeight: hasValue ? FontWeight.w700 : null),
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

    if (_isLoading) {
      return const VPageScaffold(
        title: 'Tài khoản của tôi',
        body: Center(child: VLoading(size: 40)),
      );
    }

    if (_loadError != null) {
      return VPageScaffold(
        title: 'Tài khoản của tôi',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(
                  'Không tải được hồ sơ',
                  variant: VTextVariant.headingH4,
                ),
                const VGap.sm(),
                VText(
                  _loadError!,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                  textAlign: TextAlign.center,
                ),
                const VGap.lg(),
                VButton(
                  label: 'Thử lại',
                  onPressed: _loadProfile,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                        data.hasName ? data.fullName : '(chưa có tên)',
                        variant: VTextVariant.headingH4,
                        color: data.hasName ? null : colors.textMuted,
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
