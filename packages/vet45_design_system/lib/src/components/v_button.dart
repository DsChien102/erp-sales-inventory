import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

enum VButtonVariant { primary, secondary, outline, ghost, danger, dangerOutline, warning }

enum VButtonSize { small, medium, large }

class VButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? leadingIcon;
  final bool fullWidth;
  final VButtonVariant variant;
  final VButtonSize size;
  final bool flexibleText;
  final Color? foregroundColor;

  const VButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.fullWidth = false,
    this.variant = VButtonVariant.primary,
    this.size = VButtonSize.medium,
    this.flexibleText = true,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final dynamicColors = context.vColors;

    // Size-based padding and height config
    final double height;
    final EdgeInsetsGeometry padding;
    final TextStyle textStyle;

    switch (size) {
      case VButtonSize.small:
        height = 36;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space3);
        textStyle = VTypography.bodySmall.copyWith(fontWeight: FontWeight.w600);
        break;
      case VButtonSize.medium:
        height = 44;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space4);
        textStyle = VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w600);
        break;
      case VButtonSize.large:
        height = 52;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space6);
        textStyle = VTypography.headingH4.copyWith(fontWeight: FontWeight.w600);
        break;
    }

    // Colors mapping based on variant and state
    Color? getBgColor(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        switch (variant) {
          case VButtonVariant.outline:
          case VButtonVariant.ghost:
            return Colors.transparent;
          case VButtonVariant.dangerOutline:
            return VColors.dangerBg;
          case VButtonVariant.danger:
            return VColors.dangerBg;
          case VButtonVariant.warning:
            return VColors.warningBg;
          default:
            return dynamicColors.borderStrong;
        }
      }
      switch (variant) {
        case VButtonVariant.primary:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return dynamicColors.primaryPressed;
          }
          return dynamicColors.primary;
        case VButtonVariant.secondary:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return VColors.primary100;
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
            return VColors.dangerBg;
          }
          return Colors.transparent;
        case VButtonVariant.danger:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return const Color(0xFFB53232);
          }
          return VColors.danger;
        case VButtonVariant.warning:
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
            return VColors.warning.withValues(alpha: 0.8);
          }
          return VColors.warning;
      }
    }

    Color getFgColor(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        if (variant == VButtonVariant.danger) {
          return VColors.danger.withValues(alpha: 0.5);
        }
        if (variant == VButtonVariant.dangerOutline) {
          return VColors.danger.withValues(alpha: 0.6);
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
          return VColors.danger;
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
          return BorderSide(color: VColors.danger.withValues(alpha: 0.2));
        }
        return BorderSide(color: VColors.danger);
      }
      if (variant == VButtonVariant.danger && states.contains(WidgetState.disabled)) {
        return BorderSide(color: VColors.danger.withValues(alpha: 0.15));
      }
      return BorderSide.none;
    }

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
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
          const SizedBox(width: VSpacing.space2),
        ] else if (leadingIcon != null) ...[
          leadingIcon!,
          const SizedBox(width: VSpacing.space2),
        ],
        Flexible(
          child: flexibleText
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: textStyle.copyWith(
                      color: getFgColor(isEnabled ? {} : {WidgetState.disabled}),
                    ),
                    maxLines: 1,
                  ),
                )
              : Text(
                  label,
                  style: textStyle.copyWith(
                    color: getFgColor(isEnabled ? {} : {WidgetState.disabled}),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        ),
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

    return buttonWidget;
  }
}
