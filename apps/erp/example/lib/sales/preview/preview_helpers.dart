import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Compact button row for opening sheets / dialogs / toasts in the catalog.
class PreviewActionButton extends StatelessWidget {
  const PreviewActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space2),
      child: VButton(
        label: label,
        variant: VButtonVariant.secondary,
        onPressed: onPressed,
      ),
    );
  }
}

/// Fixed-height scroll host for large forms / detail compositions.
class PreviewEmbedFrame extends StatelessWidget {
  const PreviewEmbedFrame({super.key, required this.child, this.height = 420});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderDefault),
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.card),
          child: child,
        ),
      ),
    );
  }
}

ListView previewList(List<Widget> children) {
  return ListView(
    padding: const EdgeInsets.all(VSpacing.space4),
    children: children,
  );
}
