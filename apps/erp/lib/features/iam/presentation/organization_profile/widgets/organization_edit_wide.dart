import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';

/// Bố cục Chỉnh thông tin tổ chức trên màn hình rộng (web).
class OrganizationEditWide extends StatelessWidget {
  const OrganizationEditWide({
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
      padding: const EdgeInsets.fromLTRB(
        VSpacing.screenMobile,
        VSpacing.lg,
        VSpacing.screenMobile,
        VSpacing.xl,
      ),
      children: [
        VText(
          'Thông tin liên hệ này độc lập với hồ sơ pháp lý và chứng từ đã phát hành.',
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
                  Expanded(child: phoneField),
                  const SizedBox(width: VSpacing.space5),
                  Expanded(child: emailField),
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
