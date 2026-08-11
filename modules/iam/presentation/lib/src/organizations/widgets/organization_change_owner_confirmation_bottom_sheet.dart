import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Bottom Sheet xác nhận Chuyển quyền sở hữu cho thành viên được chọn.
class OrganizationChangeOwnerConfirmationBottomSheet extends StatelessWidget {
  final OrganizationMemberUiModel member;
  final VoidCallback? onConfirm;

  const OrganizationChangeOwnerConfirmationBottomSheet({
    super.key,
    required this.member,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.space4,
        right: VSpacing.space4,
        top: VSpacing.space2,
        bottom: VSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Chuyển quyền sở hữu cho ${member.name}?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.xs(),
          VText(
            'Bạn vẫn giữ vai trò Chủ cửa hàng. ${member.name} tiếp tục giữ vai trò ${member.role}.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.lg(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.outline,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Chuyển quyền',
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
          ),
        ],
      ),
    );
  }
}
