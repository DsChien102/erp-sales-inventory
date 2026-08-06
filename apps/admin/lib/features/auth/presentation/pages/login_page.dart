// harness:allow-design-system-bypass — login shell không dùng VAppBar (branded form, không phải page ERP chuẩn)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/exception_mapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isSubmitting = false;
  String? _emailError;
  String? _passwordError;

  /// Giữ bề ngang trong khoảng breakpoint mobile trên mọi thiết bị.
  static const _mobileLayoutWidth = VResponsiveValue<double>(
    mobile: 450,
    tablet: 450,
    desktop: 450,
  );

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onCredentialsChanged);
    _passwordController.addListener(_onCredentialsChanged);
  }

  void _onCredentialsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_onCredentialsChanged)
      ..dispose();
    _passwordController
      ..removeListener(_onCredentialsChanged)
      ..dispose();
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
      requiredPasswordMessage: 'Vui lòng nhập mật khẩu',
    );

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    return emailError == null && passwordError == null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_canSubmit || !_validateFields()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final signInResult = await guard(
      () => getIt<IIamModule>().executeCommandAsync(
        SignInCommand(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          requireTenantContext: false,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    final signInFailure = signInResult.fold((f) => f, (_) => null);
    if (signInFailure != null) {
      setState(() => _isSubmitting = false);
      VToast.show(
        context,
        title: 'Đăng nhập thất bại',
        message: signInFailure.message,
        type: VToastType.danger,
      );
      return;
    }

    final gateResult = await guard(
      () =>
          getIt<IPermissionChecker>().require(IamPlatformPermissions.userView),
    );

    if (!mounted) {
      return;
    }

    final gateFailure = gateResult.fold((f) => f, (_) => null);
    if (gateFailure != null) {
      await guard(
        () => getIt<IIamModule>().executeCommandAsync(SignOutCommand()),
      );
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      VToast.show(
        context,
        title: 'Đăng nhập thất bại',
        message: 'Tài khoản không có quyền Platform Admin',
        type: VToastType.danger,
      );
      return;
    }

    setState(() => _isSubmitting = false);
    VToast.show(
      context,
      title: 'Đăng nhập thành công',
      message: 'Chào mừng bạn quay trở lại!',
      type: VToastType.success,
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Scaffold(
      backgroundColor: dynamicColors.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: VContentWidth(
            maxWidth: _mobileLayoutWidth,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
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
                          'VET45 ADMIN',
                          variant: VTextVariant.headingH1,
                          color: dynamicColors.textPrimary,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          'Nền tảng quản trị',
                          variant: VTextVariant.bodyDefault,
                          color: dynamicColors.textSecondary,
                        ),
                        const VGap.xl(),
                        VEmailField(
                          label: 'Email',
                          hintText: 'Nhập email',
                          controller: _emailController,
                          enabled: !_isSubmitting,
                          validateOnChanged: false,
                          errorText: _emailError,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                        ),
                        const VGap.md(),
                        VPasswordField(
                          label: 'Mật khẩu',
                          hintText: 'Nhập mật khẩu',
                          controller: _passwordController,
                          enabled: !_isSubmitting,
                          validateOnChanged: false,
                          errorText: _passwordError,
                          requiredPasswordMessage: 'Vui lòng nhập mật khẩu',
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                        ),
                        const VGap.lg(),
                        VButton(
                          label: 'Đăng nhập',
                          isLoading: _isSubmitting,
                          fullWidth: true,
                          onPressed: (_canSubmit && !_isSubmitting)
                              ? _submit
                              : null,
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: VSpacing.md),
                          child: VText(
                            '© VET45 · Admin',
                            variant: VTextVariant.bodySmall,
                            color: dynamicColors.textMuted,
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
}
