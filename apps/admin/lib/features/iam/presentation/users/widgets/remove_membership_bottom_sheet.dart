import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'membership_lifecycle_confirm_sheet.dart';

/// Confirm remove membership. Closes only when [onConfirm] returns true.
Future<bool?> showRemoveMembershipBottomSheet({
  required BuildContext context,
  required Future<bool> Function() onConfirm,
}) {
  return showVBottomSheet<bool>(
    context: context,
    child: MembershipLifecycleConfirmSheet(
      title: 'Loại thành viên khỏi tổ chức?',
      titleDanger: true,
      description:
          'Membership sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại.',
      confirmLabel: 'Loại thành viên',
      confirmDanger: true,
      onConfirm: onConfirm,
    ),
  );
}
