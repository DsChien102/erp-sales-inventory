import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Bố cục Hồ sơ pháp lý trên màn hình hẹp (iPhone).
class OrganizationLegalNarrow extends StatelessWidget {
  const OrganizationLegalNarrow({
    super.key,
    required this.entityField,
    required this.nameField,
    required this.taxField,
    required this.addressField,
    required this.unitsSection,
  });

  final Widget entityField;
  final Widget nameField;
  final Widget taxField;
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
              entityField,
              const VGap.md(),
              nameField,
              const VGap.md(),
              taxField,
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
                  'Thay đổi hiện tại không làm thay đổi chứng từ lịch sử.',
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
