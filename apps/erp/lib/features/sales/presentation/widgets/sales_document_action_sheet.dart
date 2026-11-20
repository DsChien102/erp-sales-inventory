import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Shared view / print / share options for sales document sheets.
final class SalesDocumentActionSheetCopy {
  const SalesDocumentActionSheetCopy({
    required this.title,
    required this.semanticLabel,
    required this.viewTitle,
    required this.viewSubtitle,
    required this.printTitle,
    required this.printSubtitle,
    required this.shareTitle,
    required this.shareSubtitle,
    required this.viewKey,
    required this.printKey,
    required this.shareKey,
  });

  final String title;
  final String semanticLabel;
  final String viewTitle;
  final String viewSubtitle;
  final String printTitle;
  final String printSubtitle;
  final String shareTitle;
  final String shareSubtitle;
  final Key viewKey;
  final Key printKey;
  final Key shareKey;
}

Future<T?> showSalesDocumentActionSheet<T>({
  required BuildContext context,
  required SalesDocumentActionSheetCopy copy,
  required T view,
  required T print,
  required T share,
}) {
  return showVBottomSheet<T>(
    context: context,
    title: copy.title,
    semanticLabel: copy.semanticLabel,
    child: _SalesDocumentActionSheetBody<T>(
      copy: copy,
      view: view,
      print: print,
      share: share,
    ),
  );
}

class _SalesDocumentActionSheetBody<T> extends StatelessWidget {
  const _SalesDocumentActionSheetBody({
    required this.copy,
    required this.view,
    required this.print,
    required this.share,
  });

  final SalesDocumentActionSheetCopy copy;
  final T view;
  final T print;
  final T share;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DocumentActionTile(
            key: copy.viewKey,
            icon: VIcons.visibility,
            title: copy.viewTitle,
            subtitle: copy.viewSubtitle,
            onTap: () => Navigator.of(context).pop(view),
          ),
          const VGap.sm(),
          _DocumentActionTile(
            key: copy.printKey,
            icon: VIcons.printer,
            title: copy.printTitle,
            subtitle: copy.printSubtitle,
            onTap: () => Navigator.of(context).pop(print),
          ),
          const VGap.sm(),
          _DocumentActionTile(
            key: copy.shareKey,
            icon: VIcons.share2,
            title: copy.shareTitle,
            subtitle: copy.shareSubtitle,
            onTap: () => Navigator.of(context).pop(share),
          ),
          const VGap.sm(),
        ],
      ),
    );
  }
}

class _DocumentActionTile extends StatelessWidget {
  const _DocumentActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      onTap: onTap,
      child: Row(
        children: [
          VIcon(icon: icon, size: 22, color: colors.textPrimary),
          const VGap.horizontalCozy(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  title,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VText(
                  subtitle,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VIcon(icon: VIcons.chevronRight, size: 20, color: colors.textMuted),
        ],
      ),
    );
  }
}
