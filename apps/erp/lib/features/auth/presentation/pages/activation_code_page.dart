import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../testing/fake_data.dart';

/// ID-D-01 — Trang Nhập mã kích hoạt.
class ActivationCodePage extends StatefulWidget {
  const ActivationCodePage({super.key});

  @override
  State<ActivationCodePage> createState() => _ActivationCodePageState();
}

class _ActivationCodePageState extends State<ActivationCodePage> {
  final _codeController = TextEditingController();
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _codeError = 'Vui lòng nhập mã kích hoạt';
      });
      VToast.show(
        context,
        title: 'Chưa nhập thông tin',
        message: 'Vui lòng nhập mã kích hoạt để tiếp tục',
        type: VToastType.danger,
      );
      return;
    }

    // Hiển thị VLoading dialog
    VLoading.show(
      context: context,
      title: 'Đang xác thực',
      description: 'Đang kiểm tra mã kích hoạt...',
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pop(); // đóng dialog

    final result = FakeActivationData.validateCode(code);

    switch (result) {
      // ID-S-01: Mã không hợp lệ
      case ActivationCodeResult.invalidCode:
        VToast.show(
          context,
          title: 'Mã kích hoạt không hợp lệ',
          message: 'Mã kích hoạt không hợp lệ. Kiểm tra và nhập lại.',
          type: VToastType.danger,
        );

      // ID-S-02: Mã đã hết hạn
      case ActivationCodeResult.expiredCode:
        VToast.show(
          context,
          title: 'Mã kích hoạt đã hết hạn',
          message:
              'Mã kích hoạt đã hết hạn. Liên hệ người gửi để nhận mã mới.',
          type: VToastType.warning,
        );

      // ID-S-03: Lời mời đã bị thu hồi
      case ActivationCodeResult.revokedInvitation:
        VToast.show(
          context,
          title: 'Lời mời đã bị thu hồi',
          message: 'Lời mời đã bị thu hồi và không thể tiếp nhận.',
          type: VToastType.danger,
        );

      // ID-S-04: Lỗi kết nối / không thể xác thực
      case ActivationCodeResult.networkError:
        VToast.show(
          context,
          title: 'Không thể xác thực mã',
          message: 'Không thể xác thực mã. Kiểm tra kết nối và thử lại.',
          type: VToastType.warning,
        );

      // Mã hợp lệ — tài khoản đã tồn tại → về login với VCard
      case ActivationCodeResult.existingAccount:
        context.go(
          '/login',
          extra: {
            'prefilledEmail': FakeActivationData.fakeEmail,
            'showSuccessBanner': true,
          },
        );

      // Mã hợp lệ — tài khoản mới → sang form kích hoạt
      case ActivationCodeResult.newAccount:
        context.push(
          '/login/activate',
          extra: {
            'email': FakeActivationData.fakeEmail,
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      title: 'Kích hoạt tài khoản',
      leading: IconButton(
        icon: VIcon(
          icon: VIcons.arrowLeft,
          color: context.vColors.textPrimary,
        ),
        onPressed: () => context.go('/login'),
      ),
      body: VContentWidth(
        maxWidth: const VResponsiveValue<double>(
          mobile: 500,
          tablet: 500,
          desktop: 500,
        ),
        child: VPagePadding(
          horizontal: VSpacing.screenMobile,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VGap.lg(),
              // Info Banner
              const VBanner(
                status: VBannerStatus.info,
                title: 'Nhập mã kích hoạt',
                description: 'Sao chép mã được gửi tới email của bạn rồi dán vào trường bên dưới.',
              ),
              const VGap.xl(),

              // Field: Mã kích hoạt
              VTextField(
                controller: _codeController,
                label: 'Mã kích hoạt',
                isRequired: true,
                hintText: 'VD: V45-A7K9-P2DX',
                errorText: _codeError,
                onChanged: (_) {
                  if (_codeError != null) {
                    setState(() => _codeError = null);
                  }
                },
                onSubmitted: (_) => _onContinue(),
              ),
              const VGap.xs(),
              VText(
                'Mã không phân biệt chữ hoa và chữ thường.',
                variant: VTextVariant.bodySmall,
                color: context.vColors.textMuted,
              ),
            ],
          ),
        ),
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: VButton(
          label: 'Tiếp tục',
          fullWidth: true,
          onPressed: _onContinue,
        ),
      ),
    );
  }
}
