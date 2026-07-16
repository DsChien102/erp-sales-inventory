import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
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
    // NOTE: nếu sau có hỗ trợ background colors cho toast riêng theo theme mode (dark hoặc light) thì update lại
    Color backgroundColor = context.vColors.textPrimary; // Dark premium background
    Color textColor = context.vColors.surface;
    Color closeIconColor = context.vColors.surface;
    final colors = context.vColors;

    final VComponentTone resolvedTone = switch (type) {
      VToastType.success => VComponentTone.success,
      VToastType.warning => VComponentTone.warning,
      VToastType.danger => VComponentTone.danger,
      VToastType.info => VComponentTone.info,
    };

    // Solid glyphs only — outline/circled Material icons double-ring on the colored disc.
    Widget iconWidget = switch (type) {
      VToastType.success => _ToastIcon(
        backgroundColor: colors.success,
        iconData: Icons.check_rounded,
      ),
      VToastType.warning => _ToastIcon(
        backgroundColor: colors.warning,
        iconData: Icons.priority_high,
      ),
      VToastType.danger => _ToastIcon(
        backgroundColor: colors.danger,
        iconData: Icons.close_rounded,
      ),
      VToastType.info => _ToastIcon(
        backgroundColor: colors.info,
        iconData: Icons.campaign_rounded,
      ),
    };

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

class _ToastIcon extends StatelessWidget {
  const _ToastIcon({
    required this.iconData,
    required this.backgroundColor,
  });

  final Color backgroundColor;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return VIconBox(
      isCircular: true,
      size: 26,
      iconSize: 16,
      iconData: iconData,
      backgroundColor: backgroundColor,
      iconColor: context.vColors.surface,
    );
  }
}
