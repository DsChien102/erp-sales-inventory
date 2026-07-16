import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerDetailLoadingSkeleton extends StatelessWidget {
  const PartnerDetailLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VSkeletonScope(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton (D-06A)
            const Row(
              children: [
                VSkeleton.circle(size: 64),
                VGap.horizontalMd(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VSkeleton(width: 160, height: 18),
                      VGap.sm(),
                      VSkeleton(width: 100, height: 14),
                      VGap.sm(),
                      VSkeleton(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const VGap.lg(),

            // List item skeletons (D-06A)
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: VSpacing.space3),
                itemBuilder: (context, index) {
                  return Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.space4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(VRadius.card),
                      border: Border.all(color: colors.borderDefault),
                    ),
                    child: const Row(
                      children: [
                        VSkeleton(width: 18, height: 18),
                        VGap.horizontalSm(),
                        Expanded(
                          child: VSkeleton(
                            width: double.infinity,
                            height: 16,
                          ),
                        ),
                        VGap.horizontalSm(),
                        VSkeleton(width: 12, height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
