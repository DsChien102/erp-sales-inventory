import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../primitives/v_divider.dart';
import '../primitives/v_icon.dart';
import '../tokens/v_breakpoints.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_bottom_sheet.dart';

/// Hộp thoại dạng sheet trên màn hình rộng, thay cho bottom sheet.
class VSheetDialog extends StatelessWidget {
  final String? title;
  final Widget child;
  final VComponentTone? tone;
  final String? semanticLabel;

  const VSheetDialog({
    super.key,
    this.title,
    required this.child,
    this.tone,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    final hasTitle = title != null && title!.isNotEmpty;

    return vInspectorHide(
      Semantics(
        label: semanticLabel ?? (hasTitle ? title : null),
        child: Dialog(
          backgroundColor: dynamicColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.sheet),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space4,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: maxHeight,
            ),
            child: hasTitle
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VSpacing.space4,
                          VSpacing.space2,
                          VSpacing.space2,
                          VSpacing.space2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  title!,
                                  style: VTypography.headingH3.copyWith(
                                    color: dynamicColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Đóng',
                              icon: VIcon(
                                icon: VIcons.close,
                                color: dynamicColors.textPrimary,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const VDivider(),
                      Flexible(
                        child: SingleChildScrollView(
                          child: vInspectorShow(child),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VSpacing.space4,
                              VSpacing.space6,
                              VSpacing.space4,
                              VSpacing.space4,
                            ),
                            child: vInspectorShow(child),
                          ),
                        ),
                        Positioned(
                          top: VSpacing.space2,
                          right: VSpacing.space2,
                          child: IconButton(
                            tooltip: 'Đóng',
                            icon: VIcon(
                              icon: VIcons.close,
                              color: dynamicColors.textPrimary,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Rộng (cửa sổ ≥ [VBreakpoints.desktop]): hộp thoại giữa màn [VSheetDialog];
/// hẹp: [showVBottomSheet].
Future<T?> showVAdaptiveSheet<T>({
  required BuildContext context,
  String? title,
  required Widget child,
  VComponentTone? tone,
  String? semanticLabel,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= VBreakpoints.desktop) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (_) => VSheetDialog(
        title: title,
        tone: tone,
        semanticLabel: semanticLabel,
        child: child,
      ),
    );
  }

  return showVBottomSheet<T>(
    context: context,
    title: title,
    tone: tone,
    semanticLabel: semanticLabel,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    child: child,
  );
}
