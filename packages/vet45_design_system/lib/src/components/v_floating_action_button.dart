import 'package:flutter/material.dart';
import '../tokens/v_shadows.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundations/icons/v_icons.dart';
import '../primitives/v_icon.dart';
import '../foundation/v_inspector_scope.dart';

class VFloatingActionButton extends StatelessWidget {
  final VIcons? icon;

  @Deprecated('Use icon instead')
  final IconData? iconData;

  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;

  const VFloatingActionButton({
    super.key,
    this.icon,
    @Deprecated('Use icon instead') this.iconData,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.tone = VComponentTone.primary,
    this.emphasis = VComponentEmphasis.strong,
    this.state,
    this.semanticLabel,
  }) : assert(icon != null || iconData != null, 'Either icon or iconData must be provided');

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

    final resolvedBgColor = backgroundColor ??
        switch (tone) {
          VComponentTone.primary => dynamicColors.primary,
          VComponentTone.danger => dynamicColors.danger,
          VComponentTone.warning => dynamicColors.warning,
          _ => dynamicColors.primary,
        };
    final resolvedIconColor = iconColor ?? Colors.white;

    final shadowAlpha = emphasis == VComponentEmphasis.strong ? 0.35 : 0.2;

    return vInspectorHide(
      Semantics(
        button: true,
        enabled: isEnabled,
        label: semanticLabel ?? 'Floating action',
        child: Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: resolvedBgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: resolvedBgColor.withValues(alpha: shadowAlpha),
                  blurRadius: emphasis == VComponentEmphasis.strong ? 16 : 8,
                  offset: const Offset(0, 8),
                ),
                if (emphasis == VComponentEmphasis.strong) ...VShadows.e3,
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: isEnabled ? onTap : null,
                customBorder: const CircleBorder(),
                child: Center(
                  child: VIcon(
                    icon: icon,
                    iconData: iconData,
                    size: 28,
                    color: resolvedIconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
