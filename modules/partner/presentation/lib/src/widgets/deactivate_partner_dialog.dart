import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_list_state.dart';

class DeactivatePartnerDialog extends StatelessWidget {
  final PartnerItemModel partner;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeactivatePartnerDialog({
    super.key,
    required this.partner,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
      title: Text('Ngừng hoạt động đối tác', style: VTypography.headingH4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(partner.name, style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Đối tác sẽ không được dùng trong giao dịch mới. Hồ sơ và dữ liệu cũ vẫn được giữ.',
            style: VTypography.bodyDefault,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel();
          },
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Ngừng hoạt động', style: TextStyle(color: VColors.danger)),
        ),
      ],
    );
  }
}
