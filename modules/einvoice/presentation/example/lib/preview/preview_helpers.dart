import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// No-op callback so catalog controls stay enabled without ERP routing.
void previewNoop() {}

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

/// Back chrome matching [VAppBar] when the catalog Navigator cannot pop.
Widget previewScaffoldBackButton(BuildContext context) {
  return IconButton(
    icon: VIcon(
      icon: VIcons.chevronLeft,
      color: context.vColors.textPrimary,
    ),
    onPressed: previewNoop,
  );
}

/// Fixed-height scroll host for large forms / detail compositions.
class PreviewEmbedFrame extends StatelessWidget {
  const PreviewEmbedFrame({
    super.key,
    required this.child,
    this.height = 420,
  });

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
          borderRadius: BorderRadius.circular(VRadius.r12),
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

Widget auditStatusBadge(BuildContext context, String label) {
  final colors = context.vColors;
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: VSpacing.space2,
      vertical: VSpacing.space1,
    ),
    decoration: BoxDecoration(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(VRadius.r8),
      border: Border.all(color: colors.borderDefault),
    ),
    child: Text(
      label,
      style: VTypography.caption.copyWith(
        color: colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
