// harness:allow-design-system-bypass — login shell không dùng VAppBar (branded form, không phải page ERP chuẩn)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/exception_mapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.prefilledEmail,
    this.showSuccessBanner = false,
  });

  final String? prefilledEmail;
  final bool showSuccessBanner;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
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

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
  }

  @override
  void didUpdateWidget(LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prefilledEmail != null && widget.prefilledEmail != oldWidget.prefilledEmail) {
      _emailController.text = widget.prefilledEmail!;
    }
  }

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

  Future<void> _navigateToResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Vui lòng nhập email trước khi đặt lại mật khẩu';
      });
      VToast.show(
        context,
        title: 'Chưa nhập email',
        message: 'Vui lòng nhập email để đặt lại mật khẩu.',
        type: VToastType.danger,
      );
      return;
    }

    final emailValidation = VEmailValidator.validate(
      email,
      isRequired: true,
      requiredEmailMessage: 'Vui lòng nhập email',
    );
    if (emailValidation != null) {
      setState(() => _emailError = emailValidation);
      return;
    }

    final result = await context.push<bool>(
      '/login/reset-password',
      extra: email,
    );
    if (!mounted) return;
    if (result == true) {
      VToast.show(
        context,
        title: 'Cập nhật mật khẩu thành công',
        message: 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.',
        type: VToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Scaffold(
      backgroundColor: dynamicColors.surface,
      body: SafeArea(
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

                      // Logo Icon
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

                      // App Title & Subtitle
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
                      const VGap.xl(),

                      // Cảnh báo mã kích hoạt hợp lệ (nếu quay lại từ màn hình nhập mã 123456 - Ảnh 4)
                      if (widget.showSuccessBanner) ...[
                        VCard(
                          tone: VComponentTone.success,
                          child: Row(
                            children: [
                              const VCardIcon(
                                icon: VIcons.success,
                                tone: VComponentTone.success,
                              ),
                              const VGap.horizontalMd(),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    VText(
                                      'Mã kích hoạt hợp lệ',
                                      variant: VTextVariant.headingH4,
                                      color: dynamicColors.success,
                                    ),
                                    const VGap.xs(),
                                    VText(
                                      'Đăng nhập đúng tài khoản để tiếp nhận lời mời và vào VET45.',
                                      variant: VTextVariant.bodySmall,
                                      color: dynamicColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const VGap.lg(),
                      ],

                      // Field 1: Số điện thoại hoặc email
                      VTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'Nhập email',
                        enabled: !_isSubmitting,
                        errorText: _emailError,
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                      ),
                      const VGap.md(),

                      // Field 2: Mật khẩu
                      VPasswordField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu',
                        minLength: 1,
                        enabled: !_isSubmitting,
                        errorText: _passwordError,
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const VGap.md(),

                      // Link: Quên mật khẩu?
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _navigateToResetPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: VText(
                            'Quên mật khẩu?',
                            variant: VTextVariant.bodyDefault,
                            color: dynamicColors.primary,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const VGap.lg(),

                      // Primary Button: Đăng nhập
                      VButton(
                        label: 'Đăng nhập',
                        isLoading: _isSubmitting,
                        fullWidth: true,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                      const VGap.lg(),

                      // Bottom action: Kích hoạt tài khoản
                      VText(
                        'Bạn đã nhận được lời mời?',
                        variant: VTextVariant.bodyDefault,
                        color: dynamicColors.textSecondary,
                      ),
                      const VGap.md(),
                      GestureDetector(
                        onTap: () => context.push('/login/enter-code'),
                        child: VText(
                          'Kích hoạt tài khoản',
                          variant: VTextVariant.bodyDefault,
                          color: dynamicColors.primary,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
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
          ),
        ),
      ),
    );
  }
}
