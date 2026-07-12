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
                color: VColors.textSecondary,
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

/// Labeled sample row inside a section.
class PreviewStateRow extends StatelessWidget {
  const PreviewStateRow({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: VTypography.caption.copyWith(
              color: VColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: VSpacing.space1),
          child,
        ],
      ),
    );
  }
}

/// Consistent wrap/column spacing for state samples.
class PreviewStateWrap extends StatelessWidget {
  const PreviewStateWrap({
    super.key,
    required this.children,
    this.spacing = VSpacing.space2,
    this.runSpacing = VSpacing.space2,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
