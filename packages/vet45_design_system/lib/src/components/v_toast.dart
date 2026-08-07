import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

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
    final colors = context.vColors;
    final backgroundColor = colors.toastSurface;
    final textColor = colors.surface;
    final closeIconColor = colors.surface;

    final VComponentTone resolvedTone = switch (type) {
      VToastType.success => VComponentTone.success,
      VToastType.warning => VComponentTone.warning,
      VToastType.danger => VComponentTone.danger,
      VToastType.info => VComponentTone.info,
    };

    Widget iconWidget = switch (type) {
      VToastType.success => _ToastIcon(
        backgroundColor: colors.success,
        icon: VIcons.success,
      ),
      VToastType.warning => _ToastIcon(
        backgroundColor: colors.warning,
        icon: VIcons.warning,
      ),
      VToastType.danger => _ToastIcon(
        backgroundColor: colors.danger,
        icon: VIcons.error,
      ),
      VToastType.info => _ToastIcon(
        backgroundColor: colors.info,
        icon: VIcons.info,
      ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: VSpacing.space1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(VRadius.r16),
        boxShadow: VShadows.e2,
        border: VBorders.all(
          type == VToastType.success
              ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
              : _toneAccent(resolvedTone, colors).withValues(alpha: 0.12),
          width: VBorders.widthFor(emphasis),
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
                      child: VText(
                        message.isNotEmpty ? message : title,
                        variant: VTextVariant.bodyDefault,
                        color: textColor,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap:
                          onClose ??
                          () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                      child: VIcon(
                        icon: VIcons.close,
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

  Color _toneAccent(VComponentTone tone, VColorScheme colors) {
    return switch (tone) {
      VComponentTone.success => colors.success,
      VComponentTone.warning => colors.warning,
      VComponentTone.danger => colors.danger,
      VComponentTone.info => colors.info,
      _ => const Color(0xFFFFFFFF),
    };
  }
}

class _ToastIcon extends StatelessWidget {
  const _ToastIcon({
    required this.icon,
    required this.backgroundColor,
  });

  final Color backgroundColor;
  final VIcons icon;

  @override
  Widget build(BuildContext context) {
    return VIconBox(
      isCircular: true,
      size: 26,
      iconSize: 16,
      icon: icon,
      backgroundColor: backgroundColor,
      iconColor: context.vColors.surface,
    );
  }
}
