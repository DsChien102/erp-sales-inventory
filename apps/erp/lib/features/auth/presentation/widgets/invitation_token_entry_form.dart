import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// ID-D-01 — Trang Nhập mã lời mời.
///
/// Layout giữ nguyên thiết kế gốc (app bar + banner + bottom bar). Ô nhập
/// alphanumeric 8 ký tự (tự viết HOA); backend chuẩn hoá (bỏ gạch + viết HOA).
class InvitationTokenEntryForm extends StatefulWidget {
  const InvitationTokenEntryForm({
    super.key,
    required this.isSubmitting,
    required this.onInspect,
    this.errorMessage,
    this.onEditing,
  });

  final bool isSubmitting;
  final ValueChanged<String> onInspect;
  final String? errorMessage;
  final VoidCallback? onEditing;

  @override
  State<InvitationTokenEntryForm> createState() => _InvitationTokenEntryFormState();
}

class _InvitationTokenEntryFormState extends State<InvitationTokenEntryForm> {
  String _token = '';
  String? _error;

  static final _tokenPattern = RegExp(r'^[0-9A-Z]{8}$');

  void _submit() {
    final token = _token.trim();
    if (!_tokenPattern.hasMatch(token)) {
      setState(
        () => _error = token.isEmpty
            ? 'Vui lòng nhập mã lời mời'
            : 'Mã lời mời phải gồm 8 ký tự chữ hoặc số',
      );
      return;
    }
    setState(() => _error = null);
    widget.onInspect(token);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isSubmitting = widget.isSubmitting;

    return VPageScaffold(
      title: 'Kích hoạt tài khoản',
      leading: IconButton(
        tooltip: 'Quay lại',
        icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
        onPressed: isSubmitting ? null : () => context.go('/login'),
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
                const VBanner(
                  status: VBannerStatus.info,
                  title: 'Nhập mã lời mời',
                  description:
                      'Sao chép mã được gửi tới email của bạn rồi dán vào '
                      'trường bên dưới.',
                ),
                const VGap.xl(),
                VField(
                  invalid: _error != null || widget.errorMessage != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VFieldLabel('Mã lời mời', isRequired: true),
                      KeyedSubtree(
                        key: const Key('invitation_token_input'),
                        child: VVerificationCodeField(
                          length: 8,
                          charset: VVerificationCodeCharset.alphanumeric,
                          autofocus: true,
                          enabled: !isSubmitting,
                          onChanged: (value) {
                            setState(() {
                              _token = value;
                              if (_error != null) _error = null;
                            });
                            widget.onEditing?.call();
                          },
                          onCompleted: (_) => _submit(),
                        ),
                      ),
                      if (_error != null || widget.errorMessage != null)
                        VFieldError(_error ?? widget.errorMessage!)
                      else
                        const VFieldDescription(
                          'Mã không phân biệt chữ hoa và chữ thường.',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: VButton(
          key: const Key('invitation_token_submit'),
          label: 'Tiếp tục',
          fullWidth: true,
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : _submit,
        ),
      ),
    );
  }
}
