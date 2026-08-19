import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../bloc/my_account_cubit.dart';
import '../bloc/my_account_state.dart';
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

  String get fullName => '$lastName $firstName'.trim();

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
    firstName: 'Minh',
    lastName: 'Nguyễn Văn',
    email: 'minh@gmail.com',
    emailStatus: 'Đã xác minh',
    phoneNumber: '0901 234 567',
  );
}

/// Trang Tài khoản của tôi (TA-D-01) — state owner: [MyAccountCubit].
class MyAccountPage extends StatelessWidget {
  const MyAccountPage({
    super.key,
    this.data,
    this.onLogout,
    this.iamModule,
    this.cubit,
  });

  /// Test-only seed when [iamModule]/[cubit] are null. Production injects module.
  final MyAccountUiModel? data;
  final Future<void> Function()? onLogout;
  final IIamModule? iamModule;
  final MyAccountCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _MyAccountBody(onLogout: onLogout),
      );
    }
    if (iamModule != null) {
      return BlocProvider(
        create: (_) => MyAccountCubit(iamModule: iamModule!)..load(),
        child: _MyAccountBody(onLogout: onLogout),
      );
    }
    assert(
      data != null,
      'MyAccountPage requires data when iamModule/cubit is null',
    );
    return _MyAccountSampleBody(
      data: data!,
      onLogout: onLogout,
    );
  }
}

class _MyAccountSampleBody extends StatefulWidget {
  const _MyAccountSampleBody({
    required this.data,
    this.onLogout,
  });

  final MyAccountUiModel data;
  final Future<void> Function()? onLogout;

  @override
  State<_MyAccountSampleBody> createState() => _MyAccountSampleBodyState();
}

class _MyAccountSampleBodyState extends State<_MyAccountSampleBody> {
  late MyAccountUiModel _accountData = widget.data;
  bool _isActionsOpen = false;

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

  Future<void> _showActionsBottomSheet() async {
    setState(() => _isActionsOpen = true);

    await showMyAccountActionsBottomSheet(
      context: context,
      onEditProfile: () async {
        final updated = await Navigator.of(context).push<MyAccountUiModel>(
          MaterialPageRoute(
            builder: (context) => EditMyAccountPage(data: _accountData),
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
              emailMasked: _maskEmail(_accountData.email),
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

  @override
  Widget build(BuildContext context) {
    return _MyAccountScaffold(
      accountData: _accountData,
      isActionsOpen: _isActionsOpen,
      onShowActions: _showActionsBottomSheet,
    );
  }
}

class _MyAccountBody extends StatefulWidget {
  const _MyAccountBody({this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  State<_MyAccountBody> createState() => _MyAccountBodyState();
}

class _MyAccountBodyState extends State<_MyAccountBody> {
  bool _isActionsOpen = false;

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

  Future<void> _showActionsBottomSheet(
    MyAccountUiModel accountData,
    IIamModule iamModule,
  ) async {
    setState(() => _isActionsOpen = true);
    final accountCubit = context.read<MyAccountCubit>();

    await showMyAccountActionsBottomSheet(
      context: context,
      onEditProfile: () async {
        final updated = await Navigator.of(context).push<MyAccountUiModel>(
          MaterialPageRoute(
            builder: (context) => EditMyAccountPage(
              data: accountData,
              iamModule: iamModule,
            ),
          ),
        );
        if (updated != null && mounted) {
          await accountCubit.load();
          if (!mounted) return;
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
              emailMasked: _maskEmail(accountData.email),
              iamModule: iamModule,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyAccountCubit, MyAccountState>(
      builder: (context, state) {
        final colors = context.vColors;
        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Tài khoản của tôi',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure || state.profile == null) {
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
                      state.failure?.message ?? 'Đã xảy ra lỗi',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const VGap.lg(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () => context.read<MyAccountCubit>().load(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final accountData = MyAccountUiModel.fromDto(state.profile!);
        final iamModule = context.read<MyAccountCubit>().iamModule;

        return _MyAccountScaffold(
          accountData: accountData,
          isActionsOpen: _isActionsOpen,
          onShowActions: () => _showActionsBottomSheet(accountData, iamModule),
        );
      },
    );
  }
}

class _MyAccountScaffold extends StatelessWidget {
  const _MyAccountScaffold({
    required this.accountData,
    required this.isActionsOpen,
    required this.onShowActions,
  });

  final MyAccountUiModel accountData;
  final bool isActionsOpen;
  final VoidCallback onShowActions;

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
    final data = accountData;

    return VPageScaffold(
      title: 'Tài khoản của tôi',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        children: [
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
                _buildInfoRow(context, 'Họ và tên đệm', data.lastName),
                _buildInfoRow(context, 'Tên', data.firstName),
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
                icon: isActionsOpen ? VIcons.chevronDown : VIcons.chevronUp,
                color: VColors.neutral0,
                size: 18,
              ),
              onPressed: onShowActions,
            ),
          ),
        ),
      ),
    );
  }
}
