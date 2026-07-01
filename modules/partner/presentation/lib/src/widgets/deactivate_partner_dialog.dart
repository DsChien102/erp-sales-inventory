import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_list_state.dart';

class DeactivatePartnerDialog extends StatelessWidget {
  const DeactivatePartnerDialog({
    super.key,
    required this.partner,
  });

  final PartnerItemModel partner;

  static Future<bool> show(
    BuildContext context, {
    required PartnerItemModel partner,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeactivatePartnerDialog(partner: partner),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
      title: Text('Ngừng hoạt động đối tác', style: VTypography.headingH4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            partner.name,
            style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Đối tác sẽ không được dùng trong giao dịch mới. Hồ sơ và dữ liệu cũ vẫn được giữ.',
            style: VTypography.bodyDefault,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ngừng hoạt động', style: TextStyle(color: VColors.danger)),
        ),
      ],
    );
  }
}
