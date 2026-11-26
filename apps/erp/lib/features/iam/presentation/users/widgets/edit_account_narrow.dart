import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';

/// Bố cục iPhone của Chỉnh sửa thông tin (ID-22).
class EditAccountNarrow extends StatelessWidget {
  const EditAccountNarrow({
    super.key,
    required this.fullName,
    required this.email,
    required this.lastNameField,
    required this.firstNameField,
    required this.phoneField,
    required this.emailField,
  });

  final String fullName;
  final String email;
  final Widget lastNameField;
  final Widget firstNameField;
  final Widget phoneField;
  final Widget emailField;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final initials = VAvatar(name: fullName).label;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      children: [
        VCard(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: VSpacing.space3,
          ),
          child: Row(
            children: [
              DetailAvatar(initials, size: 48),
              const SizedBox(width: VSpacing.space3),
              Expanded(
                child: VText(
                  'Ảnh đại diện',
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        VCard(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: lastNameField),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(flex: 2, child: firstNameField),
                ],
              ),
              const SizedBox(height: VSpacing.space4),
              phoneField,
              const SizedBox(height: VSpacing.space4),
              _ReadOnlyEmailRow(email: email),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space4),
      ],
    );
  }
}

class _ReadOnlyEmailRow extends StatelessWidget {
  const _ReadOnlyEmailRow({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Semantics(
      label: 'Email đăng nhập, $email, không sửa được',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space3,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(VRadius.input),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              Flexible(
                child: VText(
                  'Email đăng nhập',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: VSpacing.space3),
              Expanded(
                child: VText(
                  email,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              VIcon(
                icon: VIcons.lock,
                size: 16,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
