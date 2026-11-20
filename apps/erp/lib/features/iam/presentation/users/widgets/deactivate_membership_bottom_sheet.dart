import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'membership_lifecycle_confirm_sheet.dart';

/// Confirm deactivate membership. Closes only when [onConfirm] returns true.
Future<bool?> showDeactivateMembershipBottomSheet({
  required BuildContext context,
  required Future<bool> Function() onConfirm,
}) {
  return showVAdaptiveSheet<bool>(
    context: context,
    child: MembershipLifecycleConfirmSheet(
      title: 'Tạm ngừng thành viên?',
      titleDanger: true,
      description:
          'Thành viên mất quyền truy cập tới khi được kích hoạt lại.',
      confirmLabel: 'Tạm ngừng',
      confirmDanger: true,
      onConfirm: onConfirm,
    ),
  );
}
