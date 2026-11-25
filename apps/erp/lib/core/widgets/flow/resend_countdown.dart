import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Dòng gửi lại mã (prototype `.t1-verify__resend`): còn khoá là chữ thường
/// "Gửi lại mã sau mm:ss"; hết khoá là nút link "Gửi lại mã" (tắt khi [onResend] null).
class ResendCountdown extends StatelessWidget {
  const ResendCountdown({
    super.key,
    required this.remaining,
    required this.onResend,
  });

  final Duration remaining;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final locked = remaining > Duration.zero;
    return Padding(
      padding: const EdgeInsets.only(top: VSpacing.space2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VSpacing.minTouchTarget),
        child: Center(
          child: locked
              ? VText(
                  'Gửi lại mã sau ${_format(remaining)}',
                  variant: VTextVariant.bodyDefault,
                  color: context.vColors.textSecondary,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                )
              : VButton(
                  key: const Key('signup_resend'),
                  label: 'Gửi lại mã',
                  variant: VButtonVariant.link,
                  onPressed: onResend,
                ),
        ),
      ),
    );
  }

  static String _format(Duration duration) {
    final total = duration.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
