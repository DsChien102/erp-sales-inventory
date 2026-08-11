// harness:allow-design-system-bypass — login shell không dùng VAppBar (branded form, không phải page ERP chuẩn)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../../core/di/injection.dart';
import '../bloc/login_cubit.dart';
import '../bloc/login_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    this.iamModule,
    this.cubit,
    this.prefilledEmail,
    this.showSuccessBanner = false,
  });

  /// Production router injects GetIt module; tests pass explicit module/cubit.
  final IIamModule? iamModule;
  final LoginCubit? cubit;
  final String? prefilledEmail;
  final bool showSuccessBanner;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _LoginView(
          prefilledEmail: prefilledEmail,
          showSuccessBanner: showSuccessBanner,
        ),
      );
    }

    return BlocProvider(
      create: (_) => LoginCubit(iamModule: iamModule ?? getIt<IIamModule>()),
      child: _LoginView(
        prefilledEmail: prefilledEmail,
        showSuccessBanner: showSuccessBanner,
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView({
    this.prefilledEmail,
    this.showSuccessBanner = false,
  });

  final String? prefilledEmail;
  final bool showSuccessBanner;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

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
  void didUpdateWidget(_LoginView oldWidget) {
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

  void _submit() {
    final loginCubit = context.read<LoginCubit>();
    if (loginCubit.state.isSubmitting) return;
    if (!_validateFields()) return;
    loginCubit.submit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
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

    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == LoginStatus.failure && state.failure != null) {
          VToast.show(
            context,
            title: 'Đăng nhập thất bại',
            message: state.failure!.message,
            type: VToastType.danger,
          );
        }
        if (state.status == LoginStatus.success && state.session?.isAuthenticated == true) {
          VToast.show(
            context,
            title: 'Đăng nhập thành công',
            message: 'Chào mừng bạn quay trở lại!',
            type: VToastType.success,
          );
          context.go('/');
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;

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
                          const VGap.xl(),
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
                          VEmailField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'Nhập email',
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
                            controller: _passwordController,
                            label: 'Mật khẩu',
                            hintText: 'Nhập mật khẩu',
                            minLength: 1,
                            validateOnChanged: false,
                            errorText: _passwordError,
                            onChanged: (_) {
                              if (_passwordError != null) {
                                setState(() => _passwordError = null);
                              }
                            },
                            onSubmitted: (_) => _submit(),
                          ),
                          const VGap.md(),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: VButton(
                              label: 'Quên mật khẩu?',
                              variant: VButtonVariant.link,
                              onPressed: isSubmitting ? null : _navigateToResetPassword,
                            ),
                          ),
                          const VGap.lg(),
                          VButton(
                            label: 'Đăng nhập',
                            isLoading: isSubmitting,
                            fullWidth: true,
                            onPressed: isSubmitting ? null : _submit,
                          ),
                          const VGap.lg(),
                          VText(
                            'Bạn đã nhận được lời mời?',
                            variant: VTextVariant.bodyDefault,
                            color: dynamicColors.textSecondary,
                          ),
                          const VGap.md(),
                          VButton(
                            label: 'Kích hoạt tài khoản',
                            variant: VButtonVariant.link,
                            onPressed: () => context.push('/invitation'),
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
      },
    );
  }
}
