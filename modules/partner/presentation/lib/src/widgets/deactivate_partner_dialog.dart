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
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DeactivatePartnerDialog(partner: partner),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VRadius.sheet),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Ngừng hoạt động KH & NCC?',
                      style: VTypography.headingH3.copyWith(
                        color: dynamicColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Icon(Icons.close, color: dynamicColors.textPrimary, size: 24),
                  ),
                ],
              ),
            ),
            Divider(color: dynamicColors.borderDefault, height: 1),
            Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KH & NCC sẽ không thể được chọn cho giao dịch mới. Hồ sơ và lịch sử giao dịch vẫn được giữ lại.',
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: VSpacing.space2),
                  Text(
                    'Bạn có thể kích hoạt lại KH & NCC sau này.',
                    style: VTypography.bodySmall.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: VSpacing.space6),
                  Row(
                    children: [
                      Expanded(
                        child: VButton(
                          label: 'Hủy',
                          variant: VButtonVariant.outline,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: VSpacing.space3),
                      Expanded(
                        child: VButton(
                          label: 'Ngừng hoạt động',
                          variant: VButtonVariant.warning,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
