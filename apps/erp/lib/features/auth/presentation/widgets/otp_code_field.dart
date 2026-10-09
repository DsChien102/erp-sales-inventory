import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';

/// Ô nhập mã OTP 6 số.
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return TextField(
      key: const Key('otp_code_field'),
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      style: TextStyle(
        fontSize: 24,
        letterSpacing: 8,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        counterText: '',
        hintText: '••••••',
      ),
      onChanged: onChanged,
    );
  }
}
