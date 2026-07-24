import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../primitives/v_text.dart';
import '../patterns/v_gap.dart';

enum VButtonVariant { primary, secondary, outline, ghost, danger, dangerOutline, warning }

enum VButtonSize { small, medium, large }

class VButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool fullWidth;
  final VButtonVariant variant;
  final VButtonSize size;
  final bool flexibleText;
  final Color? foregroundColor;
  final VComponentTone? tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;

  const VButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = false,
    this.variant = VButtonVariant.primary,
    this.size = VButtonSize.medium,
    this.flexibleText = true,
    this.foregroundColor,
    this.tone,
    this.emphasis = VComponentEmphasis.strong,
    this.state,
    this.semanticLabel,
  });

  VComponentState _resolveState() {
    if (state != null) return state!;
    if (isLoading) return VComponentState.loading;
    if (onPressed == null) return VComponentState.disabled;
    return VComponentState.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedState = _resolveState();
    final bool isEnabled = resolvedState == VComponentState.enabled;
    final bool showLoading = resolvedState == VComponentState.loading || isLoading;
    final dynamicColors = context.vColors;

    // Size-based padding and height config
    final double height;
    final EdgeInsetsGeometry padding;
    final TextStyle textStyle;

    switch (size) {
      case VButtonSize.small:
        height = context.vDensity.controlHeightSmall;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space3);
        textStyle = VTypography.bodySmall.copyWith(fontWeight: FontWeight.w600);
        break;
      case VButtonSize.medium:
        height = context.vDensity.controlHeightMedium;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space4);
        textStyle = VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w600);
        break;
      case VButtonSize.large:
        height = context.vDensity.controlHeightLarge;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space6);
        textStyle = VTypography.headingH4.copyWith(fontWeight: FontWeight.w600);
        break;
    }

    final VComponentTone resolvedTone =
        tone ??
        switch (variant) {
          VButtonVariant.warning => VComponentTone.warning,
          VButtonVariant.danger || VButtonVariant.dangerOutline => VComponentTone.danger,
          _ => VComponentTone.primary,
        };

    // Colors mapping based on variant and state
    Color? getBgColor(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        switch (variant) {
          case VButtonVariant.outline:
          case VButtonVariant.ghost:
            return Colors.transparent;
          case VButtonVariant.dangerOutline:
            return dynamicColors.dangerBg;
          case VButtonVariant.danger:
            return dynamicColors.dangerBg;
          case VButtonVariant.warning:
            return dynamicColors.warningBg;
          default:
            return dynamicColors.borderStrong;
        }
      }
      switch (variant) {
        case VButtonVariant.primary:
          if (resolvedTone == VComponentTone.warning) {
            if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
              return dynamicColors.warning.withValues(alpha: 0.8);
            }
            return dynamicColors.warning;
          }
          if (resolvedTone == VComponentTone.danger) {
            if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
              return dynamicColors.danger.withValues(alpha: 0.85);
            }
            return dynamicColors.danger;
          }
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return dynamicColors.primaryPressed;
          }
          return dynamicColors.primary;
        case VButtonVariant.secondary:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return dynamicColors.surfaceBrand;
          }
          if (emphasis == VComponentEmphasis.subtle) {
            return dynamicColors.surface;
          }
          return dynamicColors.surfaceBrand;
        case VButtonVariant.outline:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return dynamicColors.surfaceAlt;
          }
          return dynamicColors.surface;
        case VButtonVariant.ghost:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return dynamicColors.surfaceAlt;
          }
          return Colors.transparent;
        case VButtonVariant.dangerOutline:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return dynamicColors.dangerBg;
          }
          return Colors.transparent;
        case VButtonVariant.danger:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return dynamicColors.danger.withValues(alpha: 0.85);
          }
          return dynamicColors.danger;
        case VButtonVariant.warning:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return dynamicColors.warning.withValues(alpha: 0.8);
          }
          return dynamicColors.warning;
      }
    }

    Color getFgColor(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        if (variant == VButtonVariant.danger) {
          return dynamicColors.danger.withValues(alpha: 0.5);
        }
        if (variant == VButtonVariant.dangerOutline) {
          return dynamicColors.danger.withValues(alpha: 0.6);
        }
        return dynamicColors.textMuted;
      }
      if (foregroundColor != null) {
        return foregroundColor!;
      }
      switch (variant) {
        case VButtonVariant.primary:
        case VButtonVariant.danger:
        case VButtonVariant.warning:
          return Colors.white;
        case VButtonVariant.secondary:
          return dynamicColors.primary;
        case VButtonVariant.dangerOutline:
          return dynamicColors.danger;
        case VButtonVariant.outline:
        case VButtonVariant.ghost:
          return dynamicColors.textPrimary;
      }
    }

    BorderSide getBorderSide(Set<WidgetState> states) {
      if (variant == VButtonVariant.outline) {
        return BorderSide(color: dynamicColors.borderDefault);
      }
      if (variant == VButtonVariant.dangerOutline) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: dynamicColors.danger.withValues(alpha: 0.2));
        }
        return BorderSide(color: dynamicColors.danger);
      }
      if (variant == VButtonVariant.danger && states.contains(WidgetState.disabled)) {
        return BorderSide(color: dynamicColors.danger.withValues(alpha: 0.15));
      }
      return BorderSide.none;
    }

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                getFgColor(isEnabled ? {} : {WidgetState.disabled}),
              ),
            ),
          ),
          const VGap.horizontalSm(),
        ] else if (leadingIcon != null) ...[
          leadingIcon!,
          const VGap.horizontalSm(),
        ],
        Flexible(
          child: flexibleText
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: VText(
                    label,
                    style: textStyle.copyWith(
                      color: getFgColor(isEnabled ? {} : {WidgetState.disabled}),
                    ),
                    maxLines: 1,
                  ),
                )
              : VText(
                  label,
                  style: textStyle.copyWith(
                    color: getFgColor(isEnabled ? {} : {WidgetState.disabled}),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        ),
        if (!showLoading && trailingIcon != null) ...[
          const VGap.horizontalSm(),
          trailingIcon!,
        ],
      ],
    );

    Widget buttonWidget = TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(
          Size(fullWidth ? double.infinity : 0, height),
        ),
        fixedSize: WidgetStateProperty.all(
          Size(fullWidth ? double.infinity : double.nan, height),
        ),
        padding: WidgetStateProperty.all(padding),
        backgroundColor: WidgetStateProperty.resolveWith(getBgColor),
        foregroundColor: WidgetStateProperty.resolveWith(getFgColor),
        side: WidgetStateProperty.resolveWith(getBorderSide),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.button),
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return getFgColor(states).withValues(alpha: 0.1);
          }
          return null;
        }),
      ),
      child: buttonChild,
    );

    if (height < VSpacing.minTouchTarget) {
      buttonWidget = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: VSpacing.minTouchTarget,
          minWidth: fullWidth ? double.infinity : VSpacing.minTouchTarget,
        ),
        child: Center(
          widthFactor: fullWidth ? null : 1.0,
          heightFactor: 1.0,
          child: buttonWidget,
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      child: buttonWidget,
    );
  }
}
