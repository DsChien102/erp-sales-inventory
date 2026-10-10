import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';
import '../models/platform_tenant_ui.dart';

/// C6 — xác nhận chuyển quyền sở hữu (TH-01 US-09.4 FR-02).
class PlatformChangeOwnerConfirmationSheet extends StatelessWidget {
  const PlatformChangeOwnerConfirmationSheet({
    super.key,
    required this.currentOwner,
    required this.newOwner,
    required this.onConfirm,
    this.currentOwnerName,
  });

  /// Owner hiện tại; `null` khi tổ chức chưa có Owner hoạt động.
  final PlatformTenantMember? currentOwner;

  /// Dự phòng khi [currentOwner] không có trong danh sách thành viên.
  final String? currentOwnerName;
  final PlatformTenantMember newOwner;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final oldName = currentOwner?.displayName ?? currentOwnerName ?? 'Chủ sở hữu hiện tại';

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
            'Chuyển quyền sở hữu cho ${newOwner.displayName}?',
            variant: VTextVariant.headingH3,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
          ),
          const VGap.md(),
          _OwnerLine(label: 'Chủ sở hữu hiện tại', name: oldName),
          const VGap.sm(),
          _OwnerLine(label: 'Chủ sở hữu mới', name: newOwner.displayName, emphasized: true),
          const VGap.md(),
          VText(
            '$oldName vẫn giữ vai trò Chủ cửa hàng. '
            '${newOwner.displayName} tiếp tục giữ vai trò ${newOwner.roleDisplay}. '
            'Thay đổi có hiệu lực ở yêu cầu tiếp theo.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.lg(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            key: const Key('platform_change_owner_confirm'),
            label: 'Chuyển quyền',
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      ),
    );
  }
}

class _OwnerLine extends StatelessWidget {
  const _OwnerLine({required this.label, required this.name, this.emphasized = false});

  final String label;
  final String name;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: emphasized ? colors.surfaceBrand : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(VRadius.r12),
      ),
      child: Row(
        children: [
          Expanded(
            child: VText(label, variant: VTextVariant.bodySmall, color: colors.textSecondary),
          ),
          const VGap.horizontalSm(),
          Flexible(
            child: VText(
              name,
              variant: VTextVariant.bodyDefault,
              style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
