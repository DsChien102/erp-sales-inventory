import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

Future<void> showPartnerLeaveFormDialog({
  required BuildContext context,
  required VoidCallback onLeave,
}) {
  return showVConfirmDialog(
    context: context,
    title: 'Rời khỏi màn hình?',
    message: 'Những thay đổi chưa lưu sẽ bị mất.',
    cancelLabel: 'Ở lại chỉnh sửa',
    actionLabel: 'Rời khỏi',
    isDestructive: true,
    onAction: onLeave,
  );
}
