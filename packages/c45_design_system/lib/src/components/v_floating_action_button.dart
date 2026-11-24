import 'package:flutter/material.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_shadows.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
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
  final bool? enabled;
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
    this.enabled,
    this.semanticLabel,
  }) : assert(icon != null || iconData != null, 'Either icon or iconData must be provided');

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: enabled) && onTap != null;

    final resolvedBgColor =
        backgroundColor ??
        switch (tone) {
          VComponentTone.primary => dynamicColors.primary,
          VComponentTone.danger => dynamicColors.danger,
          VComponentTone.warning => dynamicColors.warning,
          _ => dynamicColors.primary,
        };
    final resolvedIconColor = iconColor ?? dynamicColors.textInverse;

    return vInspectorHide(
      Semantics(
        button: true,
        enabled: isEnabled,
        label: semanticLabel ?? 'Floating action',
        child: vDisabledOpacity(
          enabled: isEnabled,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: resolvedBgColor,
              shape: BoxShape.circle,
              boxShadow: emphasis == VComponentEmphasis.strong ? VShadows.e3 : VShadows.e2,
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
