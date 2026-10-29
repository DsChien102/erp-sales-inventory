import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../shared/iam_action_tile.dart';

import '../bloc/organization_member_detail_state.dart';

/// Action sheet for membership lifecycle (no role-change in phase 1).
Future<void> showMemberLifecycleActionsBottomSheet({
  required BuildContext context,
  required OrganizationMemberDetailState state,
  VoidCallback? onChangeRole,
  required VoidCallback onDeactivate,
  required VoidCallback onReactivate,
  required VoidCallback onRemove,
}) {
  return showVAdaptiveSheet<void>(
    context: context,
    child: Builder(
      builder: (sheetContext) => Padding(
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
            Semantics(
              header: true,
              child: const VText(
                'Thao tác thành viên',
                variant: VTextVariant.headingH3,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const VGap.md(),
            if (state.canChangeRole && onChangeRole != null)
              IamActionTile(
                icon: VIcons.shield,
                title: 'Thay đổi vai trò',
                subtitle: 'Cập nhật vai trò',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onChangeRole();
                },
              ),
            if (state.canDeactivate) ...[
              if (state.canChangeRole && onChangeRole != null) const VGap.sm(),
              IamActionTile(
                icon: VIcons.pause,
                title: 'Tạm ngừng thành viên',
                subtitle: 'Dừng quyền truy cập tạm thời',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onDeactivate();
                },
              ),
            ],
            if (state.canReactivate) ...[
              if (state.canChangeRole && onChangeRole != null) const VGap.sm(),
              IamActionTile(
                icon: VIcons.personCheck,
                title: 'Kích hoạt lại',
                subtitle: 'Khôi phục quyền truy cập',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onReactivate();
                },
              ),
            ],
            if (state.canRemove) ...[
              if ((state.canChangeRole && onChangeRole != null) ||
                  state.canDeactivate ||
                  state.canReactivate)
                const VGap.sm(),
              IamActionTile(
                icon: VIcons.personRemove,
                title: 'Loại khỏi tổ chức',
                subtitle: 'Kết thúc tư cách thành viên',
                isDanger: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onRemove();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
