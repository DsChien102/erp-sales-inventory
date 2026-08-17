import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Section wrapper: component title + optional description + card body.
class PreviewSection extends StatelessWidget {
  const PreviewSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VTypography.headingH3),
          if (description != null) ...[
            const SizedBox(height: VSpacing.space1),
            Text(
              description!,
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: VSpacing.space2),
          VCard(child: child),
        ],
      ),
    );
  }
}
