import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// "Gửi lại mã" hoặc "Gửi lại mã sau 00:ss".
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
    final label = locked ? 'Gửi lại mã sau ${_format(remaining)}' : 'Gửi lại mã';
    return VButton(
      key: const Key('signup_resend'),
      label: label,
      variant: VButtonVariant.link,
      onPressed: locked ? null : onResend,
    );
  }

  static String _format(Duration duration) {
    final total = duration.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
