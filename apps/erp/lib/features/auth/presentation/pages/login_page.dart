// harness:allow-design-system-bypass — login shell không dùng VAppBar (branded form, không phải page ERP chuẩn)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../../../core/config/wide_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../data/auth_repository.dart';
import '../../logic/login_cubit.dart';
import '../../logic/login_state.dart';
import '../widgets/login_narrow.dart';
import '../widgets/login_wide.dart';

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
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();

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

        final emailField = KeyedSubtree(
          key: _emailKey,
          child: VField(
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
        );
        final passwordInput = KeyedSubtree(
          key: _passwordKey,
          child: VPasswordField(
            controller: _passwordController,
            hintText: 'Nhập mật khẩu',
            minLength: 1,
            validateOnChanged: false,
            autofillHints: const [AutofillHints.password],
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
        );
        final banners = <Widget>[
          if (widget.passwordResetSuccess)
            const VBanner(
              status: VBannerStatus.success,
              title: 'Cập nhật mật khẩu thành công',
              description: 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.',
            ),
          if (widget.showSuccessBanner)
            VBanner(
              status: VBannerStatus.success,
              title: 'Tham gia tổ chức thành công',
              description: joinedMessage,
            ),
        ];

        void signup() => context.push('/signup');
        void activate() => context.push('/invitation');

        final layout = isWideLayout(context)
            ? LoginWide(
                emailField: emailField,
                passwordInput: passwordInput,
                passwordError: _passwordError,
                banners: banners,
                formError: _formError,
                isSubmitting: isSubmitting,
                onSubmit: _submit,
                onForgotPassword: _navigateToResetPassword,
                onSignup: signup,
                onActivate: activate,
              )
            : LoginNarrow(
                emailField: emailField,
                passwordInput: passwordInput,
                passwordError: _passwordError,
                banners: banners,
                formError: _formError,
                isSubmitting: isSubmitting,
                onSubmit: _submit,
                onForgotPassword: _navigateToResetPassword,
                onSignup: signup,
                onActivate: activate,
              );
        // Bọc ngoài hai bố cục: đổi bố cục không huỷ nhóm (huỷ là lưu autofill đang gõ dở).
        return AutofillGroup(child: layout);
      },
    );
  }
}
