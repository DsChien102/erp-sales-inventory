import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_list_state.dart';

class ReactivatePartnerDialog extends StatelessWidget {
  const ReactivatePartnerDialog({
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
      builder: (context) => ReactivatePartnerDialog(partner: partner),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
      title: Text('Kích hoạt lại đối tác', style: VTypography.headingH4),
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
            'Đối tác sẽ được sử dụng lại trong giao dịch mới theo quyền hiện tại.',
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
          child: const Text('Kích hoạt lại', style: TextStyle(color: VColors.success)),
        ),
      ],
    );
  }
}
