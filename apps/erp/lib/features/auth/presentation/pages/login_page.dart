// harness:allow-design-system-bypass — login shell không dùng VAppBar (branded form, không phải page ERP chuẩn)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../data/auth_repository.dart';
import '../../logic/login_cubit.dart';
import '../../logic/login_state.dart';
import '../auth_layout.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    this.auth,
    this.session,
    this.cubit,
    this.prefilledEmail,
    this.organizationName,
    this.showSuccessBanner = false,
    this.passwordResetSuccess = false,
  });

  final AuthRepository? auth;
  final SessionController? session;
  final LoginCubit? cubit;
  final String? prefilledEmail;
  final String? organizationName;
  final bool showSuccessBanner;
  final bool passwordResetSuccess;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _LoginView(
          prefilledEmail: prefilledEmail,
          organizationName: organizationName,
          showSuccessBanner: showSuccessBanner,
          passwordResetSuccess: passwordResetSuccess,
        ),
      );
    }

    return BlocProvider(
      create: (_) => LoginCubit(
        auth: auth ?? getIt<AuthRepository>(),
        session: session ?? getIt<SessionController>(),
      ),
      child: _LoginView(
        prefilledEmail: prefilledEmail,
        organizationName: organizationName,
        showSuccessBanner: showSuccessBanner,
        passwordResetSuccess: passwordResetSuccess,
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView({
    this.prefilledEmail,
    this.organizationName,
    this.showSuccessBanner = false,
    this.passwordResetSuccess = false,
  });

  final String? prefilledEmail;
  final String? organizationName;
  final bool showSuccessBanner;
  final bool passwordResetSuccess;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _formError;

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
    setState(() => _formError = null);
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
    final orgName = widget.organizationName?.trim();
    final joinedMessage = (orgName != null && orgName.isNotEmpty)
        ? 'Đã tham gia tổ chức "$orgName" thành công. Đăng nhập để vào Mosaic Retail.'
        : 'Đã tham gia tổ chức thành công. Đăng nhập để vào Mosaic Retail.';

    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == LoginStatus.needsVerification) {
          context.go('/verify-email', extra: state.verificationEmail);
          return;
        }
        if (state.status == LoginStatus.failure && state.failure != null) {
          final failure = state.failure!;
          // Sai email/mật khẩu: hiện trên field email, không toast.
          if (failure.code == IamBlockedCodes.invalidCredentials) {
            setState(() {
              _emailError = failure.message;
              _passwordError = null;
              _formError = null;
            });
            return;
          }
          setState(() => _formError = failure.message);
        }
        if (state.status == LoginStatus.success && state.session?.isAuthenticated == true) {
          TextInput.finishAutofillContext();
          context.go('/');
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;

        return Scaffold(
          backgroundColor: dynamicColors.surface,
          body: SafeArea(
            child: VContentWidth(
              maxWidth: authMaxWidth,
              alignment: Alignment.topCenter,
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
                          ExcludeSemantics(
                            child: Container(
                              width: 80,
                              height: 80,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: dynamicColors.primary,
                                borderRadius: BorderRadius.circular(
                                  VRadius.r12,
                                ),
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
                          ),
                          const VGap.lg(),
                          VText(
                            'Mosaic Retail',
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
                          if (widget.passwordResetSuccess) ...[
                            const VBanner(
                              status: VBannerStatus.success,
                              title: 'Cập nhật mật khẩu thành công',
                              description: 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.',
                            ),
                            const VGap.lg(),
                          ],
                          if (widget.showSuccessBanner) ...[
                            VBanner(
                              status: VBannerStatus.success,
                              title: 'Tham gia tổ chức thành công',
                              description: joinedMessage,
                            ),
                            const VGap.lg(),
                          ],
                          AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                VField(
                                  invalid: _emailError != null,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const VFieldLabel('Email'),
                                      VEmailField(
                                        controller: _emailController,
                                        hintText: 'Nhập email',
                                        validateOnChanged: false,
                                        autofillHints: const [
                                          AutofillHints.username,
                                          AutofillHints.email,
                                        ],
                                        textInputAction: TextInputAction.next,
                                        onChanged: (_) {
                                          if (_emailError != null || _formError != null) {
                                            setState(() {
                                              _emailError = null;
                                              _formError = null;
                                            });
                                          }
                                        },
                                      ),
                                      if (_emailError != null) VFieldError(_emailError!),
                                    ],
                                  ),
                                ),
                                const VGap.md(),
                                VField(
                                  invalid: _passwordError != null,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const VFieldLabel('Mật khẩu'),
                                      VPasswordField(
                                        controller: _passwordController,
                                        hintText: 'Nhập mật khẩu',
                                        minLength: 1,
                                        validateOnChanged: false,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        textInputAction: TextInputAction.done,
                                        onChanged: (_) {
                                          if (_passwordError != null || _formError != null) {
                                            setState(() {
                                              _passwordError = null;
                                              _formError = null;
                                            });
                                          }
                                        },
                                        onSubmitted: (_) => _submit(),
                                      ),
                                      if (_passwordError != null) VFieldError(_passwordError!),
                                    ],
                                  ),
                                ),
                                if (_formError != null) ...[
                                  const VGap.md(),
                                  VBanner(
                                    status: VBannerStatus.error,
                                    title: 'Đăng nhập thất bại',
                                    description: _formError!,
                                  ),
                                ],
                              ],
                            ),
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
                          const VGap.md(),
                          VButton(
                            key: const Key('login_signup'),
                            label: 'Đăng ký cửa hàng mới',
                            variant: VButtonVariant.secondary,
                            fullWidth: true,
                            onPressed: isSubmitting ? null : () => context.push('/signup'),
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
                            onPressed: isSubmitting ? null : () => context.push('/invitation'),
                          ),
                          const Spacer(),
                          if (!kIsWeb)
                            Padding(
                              padding: const EdgeInsets.only(bottom: VSpacing.md),
                              child: VText(
                                '© Mosaic Retail · Phiên bản Mobile',
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
