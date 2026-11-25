import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_logo.dart';

/// Bố cục web của Đăng nhập (prototype `app/web/login.js`, `.t1-wlogin*`).
/// ≥ 900: khối thương hiệu cột trái 42%, form giữa cột phải. 840–899: khối thương
/// hiệu là dải trên đầu, bản quyền ở đáy cột form. Tham số như `LoginNarrow`.
class LoginWide extends StatelessWidget {
  const LoginWide({
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

  final Widget emailField;
  final Widget passwordInput;
  final String? passwordError;
  final List<Widget> banners;
  final String? formError;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignup;
  final VoidCallback onActivate;

  static const double _sideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth >= _sideBreakpoint;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: side
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth * 0.42,
                              child: _brandPanel(context, side: true),
                            ),
                            Expanded(child: _main(context, side: true)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _brandPanel(context, side: false),
                            Expanded(child: _main(context, side: false)),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _brandPanel(BuildContext context, {required bool side}) {
    final colors = context.vColors;
    final name = VText(
      'Mosaic Retail',
      variant: VTextVariant.headingH2,
      color: colors.textPrimary,
      style: side
          ? const TextStyle(fontSize: 36, height: 44 / 36, letterSpacing: -0.36)
          : const TextStyle(height: 28 / 22, letterSpacing: 0),
    );
    final tagline = VText(
      'Quản trị bán hàng thuốc thú y',
      variant: VTextVariant.bodyDefault,
      color: VColors.primary800,
      style: side
          ? const TextStyle(fontSize: 16, height: 24 / 16)
          : const TextStyle(height: 20 / 14),
    );
    final heading = Semantics(header: true, child: name);
    return Container(
      key: const Key('login_wide_panel'),
      color: colors.surfaceBrand,
      padding: side
          ? const EdgeInsets.all(VSpacing.space12)
          : const EdgeInsets.symmetric(
              vertical: VSpacing.lg,
              horizontal: VSpacing.space5,
            ),
      child: side
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(size: 72),
                    const SizedBox(height: VSpacing.lg),
                    heading,
                    const SizedBox(height: VSpacing.sm),
                    tagline,
                  ],
                ),
                VText(
                  '© Mosaic Retail',
                  variant: VTextVariant.bodySmall,
                  color: colors.textMuted,
                ),
              ],
            )
          : Row(
              children: [
                const AppLogo(size: 48),
                const SizedBox(width: VSpacing.cozy),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 2), tagline],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _main(BuildContext context, {required bool side}) {
    final colors = context.vColors;
    final content = <Widget>[
      FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (banners.isNotEmpty) ...[
              for (var i = 0; i < banners.length; i++) ...[
                if (i > 0) const SizedBox(height: VSpacing.cozy),
                banners[i],
              ],
              const SizedBox(height: VSpacing.space5),
            ],
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: emailField,
                  ),
                  const SizedBox(height: VSpacing.space5),
                  _passwordBlock(context),
                  if (formError != null) ...[
                    const SizedBox(height: VSpacing.space5),
                    VBanner(
                      status: VBannerStatus.error,
                      title: 'Đăng nhập thất bại',
                      description: formError!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: VSpacing.space5),
            FocusTraversalOrder(
              order: const NumericFocusOrder(4),
              child: VButton(
                label: 'Đăng nhập',
                isLoading: isSubmitting,
                fullWidth: true,
                onPressed: isSubmitting ? null : onSubmit,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: VSpacing.lg),
      VButton(
        key: const Key('login_signup'),
        label: 'Đăng ký cửa hàng mới',
        variant: VButtonVariant.secondary,
        fullWidth: true,
        onPressed: isSubmitting ? null : onSignup,
      ),
      const SizedBox(height: VSpacing.md),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: VSpacing.xs,
        children: [
          VText(
            'Bạn đã nhận được lời mời?',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          VButton(
            label: 'Kích hoạt tài khoản',
            variant: VButtonVariant.link,
            onPressed: isSubmitting ? null : onActivate,
          ),
        ],
      ),
    ];

    final padding = side
        ? const EdgeInsets.symmetric(
            vertical: VSpacing.space12,
            horizontal: VSpacing.xl,
          )
        : const EdgeInsets.fromLTRB(
            VSpacing.space5,
            VSpacing.xl,
            VSpacing.space5,
            VSpacing.md,
          );
    return Align(
      alignment: side ? Alignment.center : Alignment.topCenter,
      child: ConstrainedBox(
        key: const Key('login_wide_form'),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: side ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...content,
              if (!side) ...[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: VSpacing.lg),
                  child: VText(
                    '© Mosaic Retail',
                    variant: VTextVariant.bodySmall,
                    color: colors.textMuted,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Nhãn "Mật khẩu" và link "Quên mật khẩu?" cùng một dòng cao 32 (`.t1-wlogin__labelrow`).
  Widget _passwordBlock(BuildContext context) {
    final colors = context.vColors;
    return VField(
      invalid: passwordError != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VText(
                  'Mật khẩu',
                  variant: VTextVariant.headingH4,
                  color: colors.textPrimary,
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: VButton(
                    label: 'Quên mật khẩu?',
                    variant: VButtonVariant.link,
                    size: VButtonSize.small,
                    onPressed: isSubmitting ? null : onForgotPassword,
                  ),
                ),
              ],
            ),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: passwordInput,
          ),
          if (passwordError != null) VFieldError(passwordError!),
        ],
      ),
    );
  }
}
