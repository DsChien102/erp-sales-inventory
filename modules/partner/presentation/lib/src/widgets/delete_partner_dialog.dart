import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class DeletePartnerDialog extends StatelessWidget {
  const DeletePartnerDialog({
    super.key,
    required this.partnerName,
  });

  final String partnerName;

  static Future<bool> show(
    BuildContext context, {
    required String partnerName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeletePartnerDialog(partnerName: partnerName),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.sheet),
      ),
      backgroundColor: dynamicColors.surface,
      elevation: 24,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xóa hồ sơ đối tác',
              style: VTypography.headingH3.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: VSpacing.space2),
            Text(
              'Hồ sơ "$partnerName" sẽ bị xóa khỏi danh sách làm việc và không còn hiển thị trong danh sách mặc định.',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VButton(
                  label: 'Hủy',
                  variant: VButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: VSpacing.space2),
                VButton(
                  label: 'Xóa hồ sơ',
                  variant: VButtonVariant.danger,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
