import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../domain/usecases/sign_in_use_case.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _obscurePassword = true;
  var _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await getIt<SignInUseCase>()(
      email: _emailController.text.trim(),
      password: _passwordController.text,
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
    final textTheme = Theme.of(context).textTheme;
    final dynamicColors = context.vColors;

    return Scaffold(
      backgroundColor: dynamicColors.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 64),
                      Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF43C17D),
                              Color(0xFF16834D),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3335A66D),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          'V45',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'VET45',
                        style: VTypography.headingH1.copyWith(
                          color: dynamicColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quản trị bán hàng thuốc thú y',
                        style: VTypography.bodyDefault.copyWith(
                          color: dynamicColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 42),
                      _FieldLabel(
                        label: 'Số điện thoại hoặc email',
                        child: TextFormField(
                          controller: _emailController,
                          enabled: !_isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hintText: 'Nhập SĐT hoặc email',
                            prefixIcon: Icons.alternate_email_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập email hoặc số điện thoại';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(
                        label: 'Mật khẩu',
                        child: TextFormField(
                          controller: _passwordController,
                          enabled: !_isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: _inputDecoration(
                            hintText: 'Nhập mật khẩu',
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      VButton(
                        label: 'Đăng nhập',
                        isLoading: _isSubmitting,
                        fullWidth: true,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 180, bottom: 24),
                        child: Text(
                          '© VET45 · Phiên bản Mobile',
                          style: VTypography.bodySmall.copyWith(
                            color: dynamicColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final dynamicColors = context.vColors;

    return InputDecoration(
      hintText: hintText,
      hintStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textMuted),
      prefixIcon: Icon(prefixIcon, color: dynamicColors.textSecondary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: dynamicColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.input),
        borderSide: BorderSide(color: dynamicColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.input),
        borderSide: BorderSide(color: dynamicColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.input),
        borderSide: const BorderSide(color: VColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.input),
        borderSide: const BorderSide(color: VColors.danger, width: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: VTypography.headingH4.copyWith(
            color: dynamicColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        child,
      ],
    );
  }
}
