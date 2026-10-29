import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'membership_lifecycle_confirm_sheet.dart';

/// Confirm reactivate membership. Closes only when [onConfirm] returns true.
Future<bool?> showReactivateMembershipBottomSheet({
  required BuildContext context,
  required Future<bool> Function() onConfirm,
}) {
  return showVAdaptiveSheet<bool>(
    context: context,
    child: MembershipLifecycleConfirmSheet(
      title: 'Kích hoạt lại thành viên?',
      description:
          'Quyền truy cập sẽ được khôi phục theo vai trò hiện hành.',
      confirmLabel: 'Kích hoạt lại',
      onConfirm: onConfirm,
    ),
  );
}
