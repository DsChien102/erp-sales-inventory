// harness:allow-design-system-bypass — login shell không dùng VAppBar (branded form, không phải page ERP chuẩn)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/exception_mapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isSubmitting = false;
  String? _emailError;
  String? _passwordError;

  /// Giữ bề ngang trong khoảng breakpoint mobile trên mọi thiết bị.
  static const _mobileLayoutWidth = VResponsiveValue<double>(
    mobile: 500,
    tablet: 500,
    desktop: 500,
  );

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    final emailError = VEmailValidator.validate(
      _emailController.text,
      isRequired: true,
      requiredEmailMessage: 'Vui lòng nhập email',
    );
    // Login chỉ bắt buộc có mật khẩu — không enforce policy độ dài tạo mật khẩu.
    final passwordError = VPasswordValidator.validate(
      _passwordController.text,
      isRequired: true,
      minLength: 1,
    );

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    return emailError == null && passwordError == null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_validateFields()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await guard(
      () => getIt<IIamModule>().executeCommandAsync(
        SignInCommand(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        VToast.show(
          context,
          title: 'Đăng nhập thất bại',
          message: failure.message,
          type: VToastType.danger,
        );
      },
      (_) {
        VToast.show(
          context,
          title: 'Đăng nhập thành công',
          message: 'Chào mừng bạn quay trở lại!',
          type: VToastType.success,
        );
        context.go('/');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Scaffold(
      backgroundColor: dynamicColors.surface,
      body: SafeArea(
        child: VContentWidth(
          maxWidth: _mobileLayoutWidth,
          child: VPagePadding(
            horizontal: VSpacing.screenMobile,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const VGap.xxl(),
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        dynamicColors.primary,
                        dynamicColors.primaryFocus,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(VRadius.r12),
                    boxShadow: [
                      BoxShadow(
                        color: dynamicColors.surfaceBrand,
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: VText(
                    'V45',
                    variant: VTextVariant.headingH3,
                    color: dynamicColors.surface,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const VGap.lg(),
                VText(
                  'VET45',
                  variant: VTextVariant.headingH1,
                  color: dynamicColors.textPrimary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const VGap.xs(),
                VText(
                  'Quản trị bán hàng thuốc thú y',
                  variant: VTextVariant.bodyDefault,
                  color: dynamicColors.textSecondary,
                ),
                const VGap.xxl(),
                VEmailField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Nhập email',
                  enabled: !_isSubmitting,
                  errorText: _emailError,
                  prefixIcon: VIcon(icon: VIcons.mail),
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  },
                ),
                const VGap.md(),
                VPasswordField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                  minLength: 1,
                  enabled: !_isSubmitting,
                  errorText: _passwordError,
                  prefixIcon: VIcon(icon: VIcons.lock),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const VGap.xl(),
                VButton(
                  label: 'Đăng nhập',
                  isLoading: _isSubmitting,
                  fullWidth: true,
                  onPressed: _isSubmitting ? null : _submit,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.md),
                  child: VText(
                    '© VET45 · Phiên bản Mobile',
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
