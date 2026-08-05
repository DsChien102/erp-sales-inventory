import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// ID-D-01 — Trang Nhập mã lời mời.
///
/// Layout giữ nguyên thiết kế gốc (app bar + banner + bottom bar). Ô nhập tự
/// viết HOA; backend chuẩn hoá (bỏ gạch + viết HOA) nên không phân biệt hoa/thường.
class InvitationTokenEntryForm extends StatefulWidget {
  const InvitationTokenEntryForm({
    super.key,
    required this.isSubmitting,
    required this.onInspect,
  });

  final bool isSubmitting;
  final ValueChanged<String> onInspect;

  @override
  State<InvitationTokenEntryForm> createState() =>
      _InvitationTokenEntryFormState();
}

class _InvitationTokenEntryFormState extends State<InvitationTokenEntryForm> {
  late final TextEditingController _tokenController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _tokenController.clear();
    _tokenController.dispose();
    super.dispose();
  }

  void _submit() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mã lời mời');
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
        icon: VIcon(
          icon: VIcons.arrowLeft,
          color: colors.textPrimary,
        ),
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
                VTextField(
                  key: const Key('invitation_token_input'),
                  controller: _tokenController,
                  label: 'Mã lời mời',
                  isRequired: true,
                  hintText: 'VD: K7P29XQM',
                  enabled: !isSubmitting,
                  errorText: _error,
                  obscureText: false,
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) =>
                          newValue.copyWith(text: newValue.text.toUpperCase()),
                    ),
                  ],
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const VGap.xs(),
                VText(
                  'Mã không phân biệt chữ hoa và chữ thường.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: VButton(
          key: const Key('invitation_inspect_submit'),
          label: 'Tiếp tục',
          fullWidth: true,
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : _submit,
        ),
      ),
    );
  }
}
