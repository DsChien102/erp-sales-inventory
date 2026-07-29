import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../testing/fake_data.dart';

/// ID-D-02 — Trang Kích hoạt tài khoản (dành cho người dùng chưa có tài khoản).
class AccountActivationPage extends StatefulWidget {
  const AccountActivationPage({
    super.key,
    this.email,
  });

  final String? email;

  @override
  State<AccountActivationPage> createState() => _AccountActivationPageState();
}

class _AccountActivationPageState extends State<AccountActivationPage> {
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _lastNameError;
  String? _firstNameError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.email ?? FakeActivationData.fakeEmail,
    );
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    String? lastNameError;
    String? firstNameError;
    String? passwordError;
    String? confirmPasswordError;

    if (_lastNameController.text.trim().isEmpty) {
      lastNameError = 'Vui lòng nhập họ và tên đệm';
    }

    if (_firstNameController.text.trim().isEmpty) {
      firstNameError = 'Vui lòng nhập tên';
    }

    if (_passwordController.text.isEmpty) {
      passwordError = 'Vui lòng nhập mật khẩu';
    }

    if (_confirmPasswordController.text.isEmpty) {
      confirmPasswordError = 'Vui lòng nhập lại mật khẩu';
    } else if (_confirmPasswordController.text != _passwordController.text) {
      confirmPasswordError = 'Mật khẩu xác nhận không khớp';
    }

    setState(() {
      _lastNameError = lastNameError;
      _firstNameError = firstNameError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    final hasError = lastNameError != null ||
        firstNameError != null ||
        passwordError != null ||
        confirmPasswordError != null;

    if (hasError) {
      VToast.show(
        context,
        title: 'Thông tin chưa hợp lệ',
        message: 'Vui lòng kiểm tra và điền đầy đủ các trường bắt buộc',
        type: VToastType.danger,
      );
      return false;
    }

    return true;
  }

  void _onActivate() {
    if (!_validateForm()) {
      return;
    }

    // Kích hoạt thành công -> Hiển thị VToast success và về login
    VToast.show(
      context,
      title: 'Kích hoạt tài khoản thành công',
      message: 'Tài khoản đã được kích hoạt. Vui lòng đăng nhập để tiếp tục.',
      type: VToastType.success,
    );

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      title: 'Kích hoạt tài khoản',
      // Back button: pop về ActivationCodePage (không tạo page mới)
      leading: IconButton(
        icon: VIcon(
          icon: VIcons.arrowLeft,
          color: context.vColors.textPrimary,
        ),
        onPressed: () => context.pop(),
      ),
      body: VContentWidth(
        maxWidth: const VResponsiveValue<double>(
          mobile: 500,
          tablet: 500,
          desktop: 500,
        ),
        child: SingleChildScrollView(
          child: VPagePadding(
            horizontal: VSpacing.screenMobile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VGap.lg(),
                // Banner thông báo mã hợp lệ
                const VBanner(
                  status: VBannerStatus.success,
                  title: 'Mã kích hoạt hợp lệ',
                  description:
                      'Kích hoạt tài khoản để tiếp nhận lời mời và vào VET45.',
                ),
                const VGap.xl(),

                // Field 1: Họ và tên đệm
                VTextField(
                  controller: _lastNameController,
                  label: 'Họ và tên đệm',
                  isRequired: true,
                  hintText: 'Nhập họ và tên đệm',
                  errorText: _lastNameError,
                  onChanged: (_) {
                    if (_lastNameError != null) {
                      setState(() => _lastNameError = null);
                    }
                  },
                ),
                const VGap.md(),

                // Field 2: Tên
                VTextField(
                  controller: _firstNameController,
                  label: 'Tên',
                  isRequired: true,
                  hintText: 'Nhập tên',
                  errorText: _firstNameError,
                  onChanged: (_) {
                    if (_firstNameError != null) {
                      setState(() => _firstNameError = null);
                    }
                  },
                ),
                const VGap.md(),

                // Field 3: Email (disabled / read-only)
                VEmailField(
                  controller: _emailController,
                  label: 'Email',
                  enabled: false,
                ),
                const VGap.md(),

                // Field 4: Số điện thoại
                VTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hintText: 'Nhập số điện thoại',
                  keyboardType: TextInputType.phone,
                ),
                const VGap.md(),

                // Field 5: Mật khẩu
                VPasswordField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  isRequired: true,
                  hintText: 'Nhập mật khẩu',
                  minLength: 1,
                  errorText: _passwordError,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                ),
                const VGap.md(),

                // Field 6: Xác nhận mật khẩu
                VPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  isRequired: true,
                  hintText: 'Nhập lại mật khẩu',
                  minLength: 1,
                  errorText: _confirmPasswordError,
                  onChanged: (_) {
                    if (_confirmPasswordError != null) {
                      setState(() => _confirmPasswordError = null);
                    }
                  },
                  onSubmitted: (_) => _onActivate(),
                ),
                const VGap.xl(),
              ],
            ),
          ),
        ),
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: VButton(
          label: 'Kích hoạt tài khoản',
          fullWidth: true,
          onPressed: _onActivate,
        ),
      ),
    );
  }
}
