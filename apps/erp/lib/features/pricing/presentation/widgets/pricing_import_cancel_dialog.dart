import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

Future<bool> showPricingImportCancelDialog(BuildContext context) async {
  var confirmed = false;
  await showVConfirmDialog(
    context: context,
    title: 'Hủy lần nhập?',
    message: 'Lô dữ liệu đang chờ xác nhận sẽ bị hủy. Bạn có chắc muốn quay lại không?',
    cancelLabel: 'Tiếp tục nhập',
    actionLabel: 'Hủy lần nhập',
    isDestructive: true,
    onAction: () => confirmed = true,
  );
  return confirmed;
}
