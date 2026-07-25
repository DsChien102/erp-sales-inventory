import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// SC-06 — Xác nhận thoát form tạo/sửa giá riêng khi còn thay đổi chưa lưu.
Future<bool> showPriceRuleLeaveFormDialog(BuildContext context) async {
  var confirmed = false;
  await showVConfirmDialog(
    context: context,
    title: 'Rời khỏi màn hình?',
    message: 'Những thay đổi chưa lưu sẽ bị mất.',
    cancelLabel: 'Ở lại chỉnh sửa',
    actionLabel: 'Rời khỏi',
    isDestructive: true,
    onAction: () => confirmed = true,
  );
  return confirmed;
}
