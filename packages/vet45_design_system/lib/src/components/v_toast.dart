import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_shadows.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_component_contracts.dart';

enum VToastType { success, warning, danger, info }

class VToast extends StatelessWidget {
  final String title;
  final String message;
  final VToastType type;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  const VToast({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onTap,
    this.onClose,
    this.emphasis = VComponentEmphasis.strong,
    this.semanticLabel,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required VToastType type,
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: VToast(
          title: title,
          message: message,
          type: type,
          onTap: onTap,
          onClose: onClose,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Widget iconWidget;
    Color closeIconColor;

    final VComponentTone resolvedTone = switch (type) {
      VToastType.success => VComponentTone.success,
      VToastType.warning => VComponentTone.warning,
      VToastType.danger => VComponentTone.danger,
      VToastType.info => VComponentTone.info,
    };

    switch (type) {
      case VToastType.success:
        backgroundColor = VColors.neutral900; // Dark premium background
        textColor = VColors.neutral0;
        closeIconColor = VColors.neutral0.withValues(alpha: 0.54);
        iconWidget = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: VColors.success,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_rounded,
            color: VColors.neutral0,
            size: 14,
          ),
        );
        break;
      case VToastType.warning:
        backgroundColor = VColors.warningBg;
        textColor = VColors.warning;
        closeIconColor = VColors.warning.withValues(alpha: 0.6);
        iconWidget = const Icon(
          Icons.warning_amber_rounded,
          color: VColors.warning,
          size: 20,
        );
        break;
      case VToastType.danger:
        backgroundColor = VColors.dangerBg;
        textColor = VColors.danger;
        closeIconColor = VColors.danger.withValues(alpha: 0.6);
        iconWidget = const Icon(
          Icons.error_outline_rounded,
          color: VColors.danger,
          size: 20,
        );
        break;
      case VToastType.info:
        backgroundColor = VColors.infoBg;
        textColor = VColors.info;
        closeIconColor = VColors.info.withValues(alpha: 0.6);
        iconWidget = const Icon(
          Icons.info_outline_rounded,
          color: VColors.info,
          size: 20,
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: VSpacing.space1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(VRadius.r16),
        boxShadow: VShadows.e2,
        border: Border.all(
          color: type == VToastType.success
              ? VColors.neutral0.withValues(alpha: 0.06)
              : _toneAccent(resolvedTone).withValues(alpha: 0.12),
          width: emphasis == VComponentEmphasis.strong ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.r16),
        child: Material(
          color: Colors.transparent,
          child: Semantics(
            liveRegion: true,
            label: semanticLabel ?? title,
            child: InkWell(
              onTap: onTap,
              child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: 14,
              ),
              child: Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message.isNotEmpty ? message : title,
                      style: VTypography.bodyDefault.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap:
                        onClose ??
                        () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                    child: Icon(
                      Icons.close_rounded,
                      color: closeIconColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }

  Color _toneAccent(VComponentTone tone) {
    return switch (tone) {
      VComponentTone.success => VColors.success,
      VComponentTone.warning => VColors.warning,
      VComponentTone.danger => VColors.danger,
      VComponentTone.info => VColors.info,
      _ => VColors.neutral0,
    };
  }
}
