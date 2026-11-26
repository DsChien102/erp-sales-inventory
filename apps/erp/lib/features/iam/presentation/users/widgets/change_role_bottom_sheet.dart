import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'membership_lifecycle_confirm_sheet.dart';

Future<bool?> showChangeRoleBottomSheet({
  required BuildContext context,
  required String memberName,
  required String fromRole,
  required String toRole,
  required Future<bool> Function() onConfirm,
}) {
  return showVAdaptiveSheet<bool>(
    context: context,
    child: MembershipLifecycleConfirmSheet(
      title: 'Đổi vai trò của $memberName?',
      description:
          'Vai trò $fromRole → $toRole.\nVai trò là nhãn công việc; quyền nghiệp vụ của thành viên không thay đổi.',
      confirmLabel: 'Xác nhận thay đổi',
      onConfirm: onConfirm,
    ),
  );
}
