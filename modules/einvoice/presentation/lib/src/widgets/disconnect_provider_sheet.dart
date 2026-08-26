import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class DisconnectProviderSheet extends StatelessWidget {
  const DisconnectProviderSheet({
    super.key,
    required this.onConfirm,
  });

  final VoidCallback onConfirm;

  static const title = 'Ngắt kết nối MISA?';
  static const message =
      'Sau khi ngắt kết nối, không thể phát hành hóa đơn điện tử mới. Hóa đơn và lịch sử đã phát sinh vẫn được giữ nguyên.';
  static const cancelLabel = 'Giữ kết nối';
  static const actionLabel = 'Ngắt kết nối';

  @override
  Widget build(BuildContext context) {
    return VConfirmDialog(
      key: const Key('wgt_e01_u01_fr08_01'),
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      actionLabel: actionLabel,
      isDestructive: true,
      onAction: onConfirm,
    );
  }
}

Future<bool> showDisconnectProviderSheet(BuildContext context) async {
  var confirmed = false;
  await showVConfirmDialog(
    context: context,
    title: DisconnectProviderSheet.title,
    message: DisconnectProviderSheet.message,
    cancelLabel: DisconnectProviderSheet.cancelLabel,
    actionLabel: DisconnectProviderSheet.actionLabel,
    isDestructive: true,
    onAction: () {
      confirmed = true;
    },
  );
  return confirmed;
}
