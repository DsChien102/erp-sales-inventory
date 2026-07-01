import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerCancelConfirmDialog extends StatelessWidget {
  const PartnerCancelConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
      title: Text('Xác nhận thoát', style: VTypography.headingH4),
      content: Text('Bạn có dữ liệu chưa lưu. Bạn có chắc chắn muốn thoát?', style: VTypography.bodyDefault),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tiếp tục nhập'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            context.pop(); // Go back
          },
          child: const Text('Thoát', style: TextStyle(color: VColors.danger)),
        ),
      ],
    );
  }
}
