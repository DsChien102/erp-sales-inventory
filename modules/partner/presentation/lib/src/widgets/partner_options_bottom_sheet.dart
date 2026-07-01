import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onExportExcel;

  const PartnerOptionsBottomSheet({
    super.key,
    required this.onExportExcel,
  });

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
                    'Tùy chọn',
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space2),
            Divider(color: context.vColors.borderDefault, height: 1),
            const SizedBox(height: VSpacing.space2),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onExportExcel();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, color: context.vColors.textPrimary),
                    const SizedBox(width: VSpacing.space3),
                    Text(
                      'Xuất Excel',
                      style: VTypography.bodyDefault.copyWith(
                        color: context.vColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
