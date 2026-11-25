import 'package:c45_design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_logo.dart';
import '../auth_layout.dart';

/// Bố cục iPhone của Đăng nhập (prototype `app/login.js`, `.t1-login*`):
/// thương hiệu giữa, thẻ form, thẻ hai dòng lối vào, dòng bản quyền ở đáy.
class LoginNarrow extends StatelessWidget {
  const LoginNarrow({
    super.key,
    required this.emailField,
    required this.passwordInput,
    required this.passwordError,
    required this.banners,
    required this.formError,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSignup,
    required this.onActivate,
  });

  /// `VField` đủ nhãn và lỗi (trang dựng, giữ `GlobalKey`).
  final Widget emailField;

  /// `VPasswordField` trần; nhãn và lỗi do bố cục vẽ.
  final Widget passwordInput;
  final String? passwordError;
  final List<Widget> banners;
  final String? formError;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignup;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: VContentWidth(
          maxWidth: authMaxWidth,
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VSpacing.screenMobile,
                      VSpacing.xl,
                      VSpacing.screenMobile,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _brand(context),
                        for (final banner in banners) ...[
                          const SizedBox(height: VSpacing.lg),
                          banner,
                        ],
                        SizedBox(
                          height: banners.isEmpty ? VSpacing.lg : VSpacing.md,
                        ),
                        _formCard(context),
                        const SizedBox(height: VSpacing.md),
                        _entryCard(context),
                        const Spacer(),
                        if (!kIsWeb)
                          Padding(
                            padding: const EdgeInsets.only(top: VSpacing.lg),
                            child: VText(
                              '© Mosaic Retail · Phiên bản Mobile',
                              variant: VTextVariant.bodySmall,
                              color: colors.textSecondary,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(BuildContext context) {
    final colors = context.vColors;
    return Column(
      children: [
        const AppLogo(size: 64),
        const SizedBox(height: VSpacing.cozy),
        Semantics(
          header: true,
          child: VText(
            'Mosaic Retail',
            variant: VTextVariant.headingH2,
            color: colors.textPrimary,
            textAlign: TextAlign.center,
          ),
        ),
        VText(
          'Quản trị bán hàng thuốc thú y',
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _formCard(BuildContext context) {
    return VCard(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.space5,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                emailField,
                const SizedBox(height: VSpacing.md),
                VField(
                  invalid: passwordError != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Mật khẩu'),
                      passwordInput,
                      if (passwordError != null) VFieldError(passwordError!),
                    ],
                  ),
                ),
                if (formError != null) ...[
                  const SizedBox(height: VSpacing.md),
                  VBanner(
                    status: VBannerStatus.error,
                    title: 'Đăng nhập thất bại',
                    description: formError!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          VButton(
            label: 'Đăng nhập',
            isLoading: isSubmitting,
            fullWidth: true,
            onPressed: isSubmitting ? null : onSubmit,
          ),
          const SizedBox(height: VSpacing.sm),
          Center(
            child: VButton(
              label: 'Quên mật khẩu?',
              variant: VButtonVariant.link,
              onPressed: isSubmitting ? null : onForgotPassword,
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.card - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EntryRow(
              key: const Key('login_signup'),
              icon: VIcons.store,
              title: 'Đăng ký cửa hàng mới',
              onTap: isSubmitting ? null : onSignup,
            ),
            Divider(height: 1, thickness: 1, color: colors.borderDefault),
            _EntryRow(
              key: const Key('login_activate'),
              icon: VIcons.mail,
              title: 'Kích hoạt tài khoản',
              ask: 'Bạn đã nhận được lời mời?',
              onTap: isSubmitting ? null : onActivate,
            ),
          ],
        ),
      ),
    );
  }
}

/// Một dòng lối vào: icon 20, chữ (hỏi ở trên, tiêu đề đậm), mũi tên 18; cao ≥ 60.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.ask,
  });

  final VIcons icon;
  final String title;
  final String? ask;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final enabled = onTap != null;
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      VIcon(icon: icon, size: 20, color: colors.textBrand),
                      const SizedBox(width: VSpacing.cozy),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ask != null)
                              VText(
                                ask!,
                                variant: VTextVariant.bodySmall,
                                color: colors.textSecondary,
                              ),
                            VText(
                              title,
                              variant: VTextVariant.headingH4,
                              color: colors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: VSpacing.cozy),
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
        ),
      ),
    );
  }
}
