import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerCancelConfirmBottomSheet extends StatelessWidget {
  const PartnerCancelConfirmBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Bỏ thay đổi?',
                    style: VTypography.headingH3.copyWith(
                      color: context.vColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close, color: context.vColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space4),
            Text(
              'Các thông tin chưa lưu sẽ bị mất.',
              style: VTypography.bodyDefault.copyWith(
                color: context.vColors.textPrimary,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    label: 'Tiếp tục chỉnh sửa',
                    variant: VButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    label: 'Rời khỏi',
                    variant: VButtonVariant.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
