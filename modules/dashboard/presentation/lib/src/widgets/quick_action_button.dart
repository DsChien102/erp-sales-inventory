import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Dashboard shortcut tile (feature-specific action chrome).
class QuickActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.tone = VComponentTone.primary,
    this.emphasis = VComponentEmphasis.medium,
    this.state,
    this.semanticLabel,
  });

  VComponentState _resolveState() {
    if (state != null) return state!;
    if (onTap == null) return VComponentState.disabled;
    return VComponentState.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedState = _resolveState();
    final isEnabled = resolvedState == VComponentState.enabled;

    final iconBg = switch (tone) {
      VComponentTone.primary => dynamicColors.surfaceBrand,
      VComponentTone.neutral => dynamicColors.surfaceAlt,
      _ => dynamicColors.surfaceBrand,
    };

    final iconFg = switch (tone) {
      VComponentTone.primary => dynamicColors.primary,
      VComponentTone.danger => dynamicColors.danger,
      VComponentTone.warning => dynamicColors.warning,
      VComponentTone.success => dynamicColors.success,
      _ => dynamicColors.primary,
    };

    final borderWidth = VBorders.widthFor(emphasis);

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.5,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(VRadius.r16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: VSpacing.space2,
              horizontal: VSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: dynamicColors.surface,
              borderRadius: BorderRadius.circular(VRadius.r16),
              border: VBorders.all(
                dynamicColors.borderDefault,
                width: borderWidth,
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(VRadius.r12),
                      ),
                      alignment: Alignment.center,
                      child: IconTheme(
                        data: IconThemeData(color: iconFg, size: 18),
                        child: icon,
                      ),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        label,
                        style: VTypography.caption.copyWith(
                          color: dynamicColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}
