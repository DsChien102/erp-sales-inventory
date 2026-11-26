import 'package:erp/core/config/wide_layout.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/models/sign_out_result.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:erp/features/iam/data/account_repository.dart';
import 'package:erp/features/iam/data/models/my_account.dart';
import 'package:erp/features/iam/data/models/password_reset_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../shared/iam_load_status.dart';
import '../../../logic/my_account_cubit.dart';
import '../../../logic/my_account_state.dart';
import '../widgets/logout_confirmation_bottom_sheet.dart';
import '../widgets/my_account_narrow.dart';
import '../widgets/my_account_wide.dart';
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
  final bool isOwner;

  const MyAccountUiModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emailStatus,
    required this.phoneNumber,
    this.avatarUrl,
    this.isOwner = false,
  });

  String get fullName => '$lastName $firstName'.trim();

  bool get hasName => fullName.isNotEmpty;

  factory MyAccountUiModel.fromDto(
    MyAccount dto, {
    bool isOwner = false,
  }) {
    return MyAccountUiModel(
      firstName: dto.firstName,
      lastName: dto.lastName,
      email: dto.email,
      emailStatus: dto.emailVerified ? 'Đã xác minh' : 'Chưa xác minh',
      phoneNumber: dto.phoneNumber ?? '',
      avatarUrl: dto.avatarUrl,
      isOwner: isOwner,
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
    this.accountRepository,
    this.authRepository,
    this.session,
    this.cubit,
    this.onResetSignOut,
  });

  /// Test-only seed when repositories/[cubit] are null.
  final MyAccountUiModel? data;
  final Future<void> Function()? onLogout;
  final AccountRepository? accountRepository;
  final AuthRepository? authRepository;
  final SessionController? session;
  final MyAccountCubit? cubit;
  @visibleForTesting
  final Future<SignOutResult> Function()? onResetSignOut;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _MyAccountBody(
          onLogout: onLogout,
          accountRepository: accountRepository,
          authRepository: authRepository,
          session: session,
          onResetSignOut: onResetSignOut,
        ),
      );
    }
    if (accountRepository != null && session != null) {
      return BlocProvider(
        create: (_) => MyAccountCubit(
          accountRepository: accountRepository!,
          session: session!,
        )..load(),
        child: _MyAccountBody(
          onLogout: onLogout,
          accountRepository: accountRepository,
          authRepository: authRepository,
          session: session,
          onResetSignOut: onResetSignOut,
        ),
      );
    }
    assert(
      data != null,
      'MyAccountPage requires data when repositories/cubit are null',
    );
    return _MyAccountSampleBody(
      data: data!,
      onLogout: onLogout,
      session: session,
      onResetSignOut: onResetSignOut,
    );
  }
}

class _MyAccountSampleBody extends StatefulWidget {
  const _MyAccountSampleBody({
    required this.data,
    this.onLogout,
    this.session,
    this.onResetSignOut,
  });

  final MyAccountUiModel data;
  final Future<void> Function()? onLogout;
  final SessionController? session;
  final Future<SignOutResult> Function()? onResetSignOut;

  @override
  State<_MyAccountSampleBody> createState() => _MyAccountSampleBodyState();
}

class _MyAccountSampleBodyState extends State<_MyAccountSampleBody> {
  late MyAccountUiModel _accountData = widget.data;
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await widget.onLogout?.call();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _editProfile() async {
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
  }

  Future<void> _resetPassword() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ResetPasswordPage(
          emailMasked: maskEmail(_accountData.email),
        ),
      ),
    );
    if (result == true && mounted) {
      await _openLoginAfterPasswordReset(
        context,
        widget.session,
        signOutOverride: widget.onResetSignOut,
      );
    }
  }

  void _confirmLogout() {
    if (_loggingOut) return;
    showLogoutConfirmationBottomSheet(
      context: context,
      onConfirm: _logout,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MyAccountScaffold(
      accountData: _accountData,
      loggingOut: _loggingOut,
      onEdit: _editProfile,
      onResetPassword: _resetPassword,
      onLogout: _confirmLogout,
    );
  }
}

class _MyAccountBody extends StatefulWidget {
  const _MyAccountBody({
    this.onLogout,
    this.accountRepository,
    this.authRepository,
    this.session,
    this.onResetSignOut,
  });

  final Future<void> Function()? onLogout;
  final AccountRepository? accountRepository;
  final AuthRepository? authRepository;
  final SessionController? session;
  final Future<SignOutResult> Function()? onResetSignOut;

  @override
  State<_MyAccountBody> createState() => _MyAccountBodyState();
}

class _MyAccountBodyState extends State<_MyAccountBody> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await widget.onLogout?.call();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _editProfile() async {
    final accountCubit = context.read<MyAccountCubit>();
    final updated = await Navigator.of(context).push<MyAccountUiModel>(
      MaterialPageRoute(
        builder: (context) => EditMyAccountPage(
          accountRepository: widget.accountRepository,
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
  }

  Future<void> _resetPassword(MyAccountUiModel accountData) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ResetPasswordPage(
          emailMasked: maskEmail(accountData.email),
          authRepository: widget.authRepository,
        ),
      ),
    );
    if (result == true && mounted) {
      await _openLoginAfterPasswordReset(
        context,
        widget.session,
        signOutOverride: widget.onResetSignOut,
      );
    }
  }

  void _confirmLogout() {
    if (_loggingOut) return;
    showLogoutConfirmationBottomSheet(
      context: context,
      onConfirm: _logout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBack = MediaQuery.sizeOf(context).width < VBreakpoints.desktop;
    return BlocBuilder<MyAccountCubit, MyAccountState>(
      builder: (context, state) {
        final colors = context.vColors;
        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return VPageScaffold(
            title: 'Tài khoản của tôi',
            showBackButton: showBack,
            body: const Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure || state.profile == null) {
          return VPageScaffold(
            title: 'Tài khoản của tôi',
            showBackButton: showBack,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: VText(
                        'Không tải được hồ sơ',
                        variant: VTextVariant.headingH4,
                      ),
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

        final accountData = MyAccountUiModel.fromDto(
          state.profile!,
          isOwner: state.isOwner,
        );
        return _MyAccountScaffold(
          accountData: accountData,
          loggingOut: _loggingOut,
          onEdit: _editProfile,
          onResetPassword: () => _resetPassword(accountData),
          onLogout: _confirmLogout,
        );
      },
    );
  }
}

class _MyAccountScaffold extends StatelessWidget {
  const _MyAccountScaffold({
    required this.accountData,
    required this.loggingOut,
    required this.onEdit,
    required this.onResetPassword,
    required this.onLogout,
  });

  static const _wideContentMaxWidth = VResponsiveValue<double>(
    mobile: double.infinity,
    tablet: 1040,
    desktop: 1040,
  );

  final MyAccountUiModel accountData;
  final bool loggingOut;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final showBack = MediaQuery.sizeOf(context).width < VBreakpoints.desktop;

    return VPageScaffold(
      title: 'Tài khoản của tôi',
      showBackButton: showBack,
      contentMaxWidth: wide
          ? _wideContentMaxWidth
          : VPageScaffold.defaultContentMaxWidth,
      body: wide
          ? MyAccountWide(
              data: accountData,
              onEdit: onEdit,
              onResetPassword: onResetPassword,
              onLogout: onLogout,
              loggingOut: loggingOut,
            )
          : MyAccountNarrow(
              data: accountData,
              onEdit: onEdit,
              onResetPassword: onResetPassword,
              onLogout: onLogout,
              loggingOut: loggingOut,
            ),
    );
  }
}

Future<void> _openLoginAfterPasswordReset(
  BuildContext context,
  SessionController? session, {
  Future<SignOutResult> Function()? signOutOverride,
}) async {
  final signOut = signOutOverride ?? session?.signOut;
  if (signOut != null) {
    try {
      final result = await signOut();
      if (!context.mounted) return;
      if (!result.localCleared) {
        VToast.show(
          context,
          title: 'Đăng xuất thất bại',
          message: 'Không thể đóng phiên trên máy.',
          type: VToastType.danger,
        );
        return;
      }
    } on AppException catch (error) {
      if (!context.mounted) return;
      VToast.show(
        context,
        title: 'Đăng xuất thất bại',
        message: error.userMessage(),
        type: VToastType.danger,
      );
      return;
    } catch (_) {
      if (!context.mounted) return;
      VToast.show(
        context,
        title: 'Đăng xuất thất bại',
        message: 'Không thể đóng phiên trên máy.',
        type: VToastType.danger,
      );
      return;
    }
  }
  if (!context.mounted) return;
  context.go('/login', extra: <String, dynamic>{'passwordResetSuccess': true});
}
