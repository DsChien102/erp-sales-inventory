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
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReactivatePartnerDialog(partner: partner),
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
                  Text(
                    'Kích hoạt lại KH & NCC?',
                    style: VTypography.headingH3.copyWith(
                      color: dynamicColors.textPrimary,
                      fontWeight: FontWeight.w700,
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
                    'KH & NCC sẽ có thể được chọn cho giao dịch mới nếu đáp ứng các điều kiện nghiệp vụ khác.',
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textPrimary,
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
                          label: 'Kích hoạt lại',
                          variant: VButtonVariant.primary,
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
