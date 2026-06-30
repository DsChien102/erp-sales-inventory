import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerDuplicateWarningDialog extends StatelessWidget {
  final List<String> warnings;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const PartnerDuplicateWarningDialog({
    super.key,
    required this.warnings,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
      title: Text('Cảnh báo trùng lặp', style: VTypography.headingH4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hệ thống phát hiện dữ liệu có khả năng trùng:', style: VTypography.bodyDefault),
          const SizedBox(height: 8),
          ...warnings.map((w) => Text('- $w', style: VTypography.bodyDefault.copyWith(color: VColors.danger))),
          const SizedBox(height: 16),
          Text('Bạn có muốn tiếp tục lưu hồ sơ này?', style: VTypography.bodyDefault),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel();
          },
          child: const Text('Quay lại kiểm tra'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Vẫn tiếp tục lưu', style: TextStyle(color: VColors.success)),
        ),
      ],
    );
  }
}
