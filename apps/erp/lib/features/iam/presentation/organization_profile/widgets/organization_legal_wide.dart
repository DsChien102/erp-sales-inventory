import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';

/// Bố cục Hồ sơ pháp lý trên màn hình rộng (web).
class OrganizationLegalWide extends StatelessWidget {
  const OrganizationLegalWide({
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
      padding: const EdgeInsets.fromLTRB(
        VSpacing.screenMobile,
        VSpacing.lg,
        VSpacing.screenMobile,
        VSpacing.xl,
      ),
      children: [
        VText(
          'Thay đổi hiện tại không làm thay đổi chứng từ lịch sử.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const VGap.md(),
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nameField,
              const VGap.md(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: entityField),
                  const SizedBox(width: VSpacing.space5),
                  Expanded(child: taxField),
                ],
              ),
              const VGap.md(),
              addressField,
              const VGap.md(),
              unitsSection,
            ],
          ),
        ),
      ],
    );
  }
}
