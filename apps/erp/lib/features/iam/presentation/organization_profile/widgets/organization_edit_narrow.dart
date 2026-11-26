import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Bố cục Chỉnh thông tin tổ chức trên màn hình hẹp (iPhone).
class OrganizationEditNarrow extends StatelessWidget {
  const OrganizationEditNarrow({
    super.key,
    required this.nameField,
    required this.phoneField,
    required this.emailField,
    required this.addressField,
    required this.unitsSection,
  });

  final Widget nameField;
  final Widget phoneField;
  final Widget emailField;
  final Widget addressField;
  final Widget unitsSection;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        VCard(
          backgroundColor: colors.surface,
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nameField,
              const VGap.md(),
              phoneField,
              const VGap.md(),
              emailField,
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        VCard(
          backgroundColor: colors.surface,
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              unitsSection,
              const VGap.md(),
              addressField,
            ],
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: VIcon(
                  icon: VIcons.info,
                  size: 16,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VText(
                  'Thông tin liên hệ này độc lập với hồ sơ pháp lý và chứng từ đã phát hành.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
