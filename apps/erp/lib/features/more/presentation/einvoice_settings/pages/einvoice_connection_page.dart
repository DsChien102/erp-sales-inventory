import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/einvoice_settings_cubit.dart';
import '../bloc/einvoice_settings_state.dart';

class EInvoiceConnectionPage extends StatefulWidget {
  const EInvoiceConnectionPage({super.key, required this.cubit});

  final EInvoiceSettingsCubit cubit;

  @override
  State<EInvoiceConnectionPage> createState() => _EInvoiceConnectionPageState();
}

class _EInvoiceConnectionPageState extends State<EInvoiceConnectionPage> {
  late final TextEditingController _providerController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _appIdController;

  String? _taxCodeError;
  String? _usernameError;
  String? _passwordError;
  String? _appIdError;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    _providerController = TextEditingController(text: 'MISA meInvoice');
    _taxCodeController = TextEditingController(text: state.taxCode);
    _usernameController = TextEditingController(text: state.username);
    _passwordController = TextEditingController(text: state.password);
    _appIdController = TextEditingController(text: state.appId);
  }

  @override
  void dispose() {
    _providerController.dispose();
    _taxCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _appIdController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _taxCodeController.text.trim().isNotEmpty &&
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: VTypography.bodyDefault.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? VColors.danger : VColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        margin: const EdgeInsets.all(VSpacing.space4),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _taxCodeError = null;
      _usernameError = null;
      _passwordError = null;
      _appIdError = null;
    });

    bool isValid = true;

    final taxCode = _taxCodeController.text.trim();
    if (taxCode.isEmpty) {
      _taxCodeError = 'Vui lòng nhập mã số thuế';
      isValid = false;
    } else if (taxCode.length < 10) {
      _taxCodeError = 'Mã số thuế phải có ít nhất 10 ký tự';
      isValid = false;
    }

    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _usernameError = 'Vui lòng nhập tài khoản kết nối';
      isValid = false;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = 'Vui lòng nhập mật khẩu kết nối';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    final success = await widget.cubit.saveConnection(
      taxCode: taxCode,
      username: username,
      password: password,
      appId: _appIdController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _showToast(context, 'Kết nối và lưu cấu hình MISA meInvoice thành công!');
      context.pop(true);
    } else {
      final error = widget.cubit.state.errorMessage ?? 'Có lỗi xảy ra, vui lòng thử lại';
      _showToast(context, error, isError: true);
    }
  }

  Future<void> _retestConnection() async {
    final success = await widget.cubit.retestConnection();
    if (!mounted) return;
    if (success) {
      _showToast(context, 'Kiểm tra kết nối thành công!');
    } else {
      final error = widget.cubit.state.errorMessage ?? 'Kiểm tra kết nối thất bại';
      _showToast(context, error, isError: true);
    }
  }

  Future<void> _confirmDisconnect() async {
    final colors = context.vColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Ngắt kết nối MISA meInvoice?',
            style: VTypography.headingH3.copyWith(color: colors.textPrimary),
          ),
          content: Text(
            'Sau khi ngắt kết nối, các nghiệp vụ HĐĐT phụ thuộc kết nối sẽ bị vô hiệu hóa.',
            style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Hủy',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            VButton(
              label: 'Ngắt kết nối',
              variant: VButtonVariant.danger,
              size: VButtonSize.small,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await widget.cubit.disconnect();
      if (!mounted) return;
      if (success) {
        _showToast(context, 'Đã ngắt kết nối MISA meInvoice');
        _passwordController.clear();
        setState(() {});
      } else {
        final error = widget.cubit.state.errorMessage ?? 'Có lỗi xảy ra';
        _showToast(context, error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<EInvoiceSettingsCubit, EInvoiceSettingsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colors.background,
            appBar: VAppBar(
              title: 'Kết nối dịch vụ hóa đơn điện tử',
              showBackButton: !state.isSubmitting,
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.screenMobile,
                      vertical: VSpacing.space4,
                    ),
                    children: [
                      // Card 1: Provider and connection state
                      VCard(
                        padding: const EdgeInsets.all(VSpacing.space4),
                        child: Row(
                          children: [
                            VIconBox(
                              icon: VIcons.power,
                              size: 40,
                              iconSize: 20,
                              backgroundColor: colors.surfaceBrand,
                              iconColor: colors.primary,
                              borderRadius: VRadius.r12,
                            ),
                            const SizedBox(width: VSpacing.space3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MISA meInvoice',
                                    style: VTypography.headingH4.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  VBadge(
                                    label: state.misaConnected ? 'ĐANG KẾT NỐI' : 'CHƯA KẾT NỐI',
                                    status: state.misaConnected
                                        ? VBadgeStatus.completed
                                        : VBadgeStatus.draft,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: VSpacing.space4),

                      // Card 2: Form fields
                      VCard(
                        padding: const EdgeInsets.all(VSpacing.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Read-only provider
                            VTextField(
                              label: 'Nhà cung cấp',
                              controller: _providerController,
                              enabled: false,
                            ),
                            const SizedBox(height: VSpacing.space4),

                            // Unit Tax Code
                            VTextField(
                              label: 'Mã số thuế đơn vị phát hành',
                              controller: _taxCodeController,
                              enabled: !state.isSubmitting,
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              hintText: 'Nhập mã số thuế',
                              errorText: _taxCodeError,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: VSpacing.space4),

                            // MISA Username
                            VTextField(
                              label: 'Tài khoản MISA meInvoice',
                              controller: _usernameController,
                              enabled: !state.isSubmitting,
                              isRequired: true,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'username',
                              errorText: _usernameError,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: VSpacing.space4),

                            // Password
                            VTextField(
                              label: state.misaConnected ? 'Mật khẩu (để trống nếu không đổi)' : 'Mật khẩu',
                              controller: _passwordController,
                              enabled: !state.isSubmitting,
                              isRequired: !state.misaConnected,
                              obscureText: _obscurePassword,
                              hintText: 'Nhập mật khẩu',
                              errorText: _passwordError,
                              onChanged: (_) => setState(() {}),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: VIcon(
                                  icon: _obscurePassword
                                      ? VIcons.visibility
                                      : VIcons.visibilityOff,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: VSpacing.space4),

                            // App ID
                            VTextField(
                              label: 'App ID',
                              controller: _appIdController,
                              enabled: !state.isSubmitting,
                              isRequired: true,
                              hintText: 'Nhập mã AppID',
                              errorText: _appIdError,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: VSpacing.space4),

                            // Helper Text
                            Text(
                              'Thông tin xác thực được lưu mã hóa. Sau khi lưu, mật khẩu chỉ hiển thị dạng che.',
                              style: VTypography.bodySmall.copyWith(
                                color: colors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions section when connected
                      if (state.misaConnected) ...[
                        const SizedBox(height: VSpacing.space4),
                        VButton(
                          label: 'Kiểm tra lại kết nối',
                          leadingIcon: VIcon(icon: VIcons.refresh, color: colors.textPrimary, size: 18),
                          variant: VButtonVariant.outline,
                          fullWidth: true,
                          isLoading: state.isSubmitting,
                          onPressed: state.isSubmitting ? null : _retestConnection,
                        ),
                        const SizedBox(height: VSpacing.space3),
                        InkWell(
                          onTap: state.isSubmitting ? null : _confirmDisconnect,
                          borderRadius: BorderRadius.circular(VRadius.button),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: VColors.dangerBg,
                              border: Border.all(color: VColors.danger.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(VRadius.button),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const VIcon(
                                  icon: VIcons.powerOff,
                                  color: VColors.danger,
                                  size: 18,
                                ),
                                const SizedBox(width: VSpacing.space2),
                                Text(
                                  'Ngắt kết nối',
                                  style: VTypography.bodyDefault.copyWith(
                                    color: VColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Pinned Bottom Action Button
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(top: BorderSide(color: colors.borderDefault)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    VSpacing.space4,
                    VSpacing.space3,
                    VSpacing.space4,
                    VSpacing.space3 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: VButton(
                    label: 'Lưu & kiểm tra kết nối',
                    leadingIcon: const VIcon(icon: VIcons.check, color: Colors.white, size: 18),
                    isLoading: state.isSubmitting,
                    fullWidth: true,
                    onPressed: (state.isSubmitting || !_isFormValid) ? null : _submit,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
