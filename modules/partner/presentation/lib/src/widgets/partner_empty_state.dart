import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const PartnerEmptyState({
    super.key,
    this.title = 'Không tìm thấy KH & NCC phù hợp',
    this.message = 'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc.',
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VColors.successBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 40,
                color: VColors.success,
              ),
            ),
            const SizedBox(height: VSpacing.space4),
            Text(
              title,
              style: VTypography.headingH4.copyWith(
                color: dynamicColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.space2),
            Text(
              message,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
