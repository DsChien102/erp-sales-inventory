import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Thanh dưới cố định của C2 chứa nút "Thao tác".
class PlatformOrganizationBottomBar extends StatelessWidget {
  const PlatformOrganizationBottomBar({super.key, required this.onActionTap});

  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space3,
          ),
          child: VButton(
            label: 'Thao tác',
            onPressed: onActionTap,
            fullWidth: true,
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
            trailing: VIcons.chevronUp,
          ),
        ),
      ),
    );
  }
}
