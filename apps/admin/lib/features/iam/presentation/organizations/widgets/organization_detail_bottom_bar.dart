import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Bottom bar cố định dưới cùng chứa nút "Thao tác ^" màu xanh lá.
class OrganizationDetailBottomBar extends StatelessWidget {
  final VoidCallback? onActionTap;

  const OrganizationDetailBottomBar({
    super.key,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.borderDefault),
        ),
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
            onPressed: onActionTap ?? () {},
            fullWidth: true,
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
            trailingIcon: const VIcon(
              icon: VIcons.chevronUp,
              size: 20,
              iconColor: VIconColor.white,
            ),
          ),
        ),
      ),
    );
  }
}
