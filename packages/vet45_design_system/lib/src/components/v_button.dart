import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../primitives/v_text.dart';
import '../patterns/v_gap.dart';
import '../foundation/v_inspector_scope.dart';

enum VButtonVariant {
  primary,

  /// Bordered secondary action (formerly outline).
  secondary,

  /// Borderless tertiary action (formerly ghost).
  tertiary,

  /// Text-only action: no fill/splash/padding; underline on hover, focus, or press.
  link,
}

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

  static TextStyle _textStyleForVariant(VButtonVariant variant) {
    return switch (variant) {
      VButtonVariant.primary => VTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      VButtonVariant.secondary => VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w500),
      VButtonVariant.tertiary => VTypography.headingH4.copyWith(fontWeight: FontWeight.w600),
      VButtonVariant.link => VTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedState = _resolveState();
    final bool isEnabled = resolvedState == VComponentState.enabled;
    final bool showLoading = resolvedState == VComponentState.loading || isLoading;
    final dynamicColors = context.vColors;

    if (variant == VButtonVariant.link) {
      return vInspectorHide(
        _VButtonLink(
          label: label,
          onPressed: onPressed,
          isEnabled: isEnabled,
          showLoading: showLoading,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          textStyle: _textStyleForVariant(variant),
          foregroundColor: foregroundColor,
          semanticLabel: semanticLabel,
        ),
      );
    }

    // Size-based padding and height config
    final double height;
    final EdgeInsetsGeometry padding;
    final TextStyle textStyle = _textStyleForVariant(variant);

    switch (size) {
      case VButtonSize.small:
        height = context.vDensity.controlHeightSmall;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space3);
        break;
      case VButtonSize.medium:
        height = context.vDensity.controlHeightMedium;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space4);
        break;
      case VButtonSize.large:
        height = context.vDensity.controlHeightLarge;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space6);
        break;
    }

    final VComponentTone resolvedTone = tone ?? VComponentTone.primary;

    // Colors mapping based on variant × tone and state
    Color? getBgColor(Set<WidgetState> states) {
      final disabled = states.contains(WidgetState.disabled);
      final pressed = states.contains(WidgetState.pressed);
      final hovered = states.contains(WidgetState.hovered);

      if (disabled) {
        switch (variant) {
          case VButtonVariant.secondary:
          case VButtonVariant.tertiary:
            return Colors.transparent;
          case VButtonVariant.primary:
            if (resolvedTone == VComponentTone.danger) {
              return dynamicColors.dangerBg;
            }
            if (resolvedTone == VComponentTone.warning) {
              return dynamicColors.warningBg;
            }
            return dynamicColors.primaryDisabled;
          case VButtonVariant.link:
            return Colors.transparent;
        }
      }

      // pressed && hovered is for web behavior
      // pressed || hovered is for mobile behavior
      switch (variant) {
        case VButtonVariant.primary:
          if (resolvedTone == VComponentTone.warning) {
            if (pressed && hovered) return dynamicColors.warningPressed;
            if (pressed || hovered) return dynamicColors.warningHover;
            return dynamicColors.warning;
          }
          if (resolvedTone == VComponentTone.danger) {
            if (pressed && hovered) return dynamicColors.dangerPressed;
            if (pressed || hovered) return dynamicColors.dangerHover;
            return dynamicColors.danger;
          }
          if (pressed && hovered) return dynamicColors.primaryPressed;
          if (pressed || hovered) return dynamicColors.primaryHover;
          return dynamicColors.primary;
        case VButtonVariant.secondary:
          if (resolvedTone == VComponentTone.danger) {
            if (pressed && hovered) return dynamicColors.dangerBgPressed;
            if (pressed || hovered) return dynamicColors.dangerBg;
            return Colors.transparent;
          }
          if (resolvedTone == VComponentTone.warning) {
            if (pressed && hovered) return dynamicColors.warningBgPressed;
            if (pressed || hovered) return dynamicColors.warningBg;
            return Colors.transparent;
          }
          if (pressed) return dynamicColors.surfacePressed;
          if (hovered) return dynamicColors.surfaceHover;
          return dynamicColors.surface;
        case VButtonVariant.tertiary:
          if (resolvedTone == VComponentTone.danger) {
            if (pressed && hovered) return dynamicColors.dangerBgPressed;
            if (pressed || hovered) return dynamicColors.dangerBg;
            return Colors.transparent;
          }
          if (resolvedTone == VComponentTone.warning) {
            if (pressed && hovered) return dynamicColors.warningBgPressed;
            if (pressed || hovered) return dynamicColors.warningBg;
            return Colors.transparent;
          }
          if (pressed && hovered) return dynamicColors.successBgPressed;
          if (pressed || hovered) return dynamicColors.successBg;
          return Colors.transparent;
        case VButtonVariant.link:
          // Unreachable: link uses `_VButtonLink` early return.
          return Colors.transparent;
      }
    }

    Color getFgColor(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        if (variant == VButtonVariant.primary && resolvedTone == VComponentTone.danger) {
          return dynamicColors.danger.withValues(alpha: 0.5);
        }
        if (variant == VButtonVariant.secondary && resolvedTone == VComponentTone.danger) {
          return dynamicColors.danger.withValues(alpha: 0.6);
        }
        return dynamicColors.textMuted;
      }
      if (foregroundColor != null) {
        return foregroundColor!;
      }
      switch (variant) {
        case VButtonVariant.primary:
          return dynamicColors.textInverse;
        case VButtonVariant.link:
          return dynamicColors.primary;
        case VButtonVariant.secondary:
          if (resolvedTone == VComponentTone.danger) {
            return dynamicColors.danger;
          }
          if (resolvedTone == VComponentTone.warning) {
            return dynamicColors.warning;
          }
          return dynamicColors.textPrimary;
        case VButtonVariant.tertiary:
          if (resolvedTone == VComponentTone.danger) {
            return dynamicColors.danger;
          }
          if (resolvedTone == VComponentTone.warning) {
            return dynamicColors.warning;
          }
          return dynamicColors.textBrand;
      }
    }

    BorderSide getBorderSide(Set<WidgetState> states) {
      final disabled = states.contains(WidgetState.disabled);

      if (variant == VButtonVariant.secondary) {
        if (resolvedTone == VComponentTone.danger) {
          if (disabled) {
            return VBorders.side(dynamicColors.danger.withValues(alpha: 0.2));
          }
          return VBorders.side(dynamicColors.danger);
        }
        if (resolvedTone == VComponentTone.warning) {
          if (disabled) {
            return VBorders.side(dynamicColors.warning.withValues(alpha: 0.2));
          }
          return VBorders.side(dynamicColors.warning);
        }
        return VBorders.side(dynamicColors.borderStrong);
      }

      if (variant == VButtonVariant.primary && resolvedTone == VComponentTone.danger && disabled) {
        return VBorders.side(dynamicColors.danger.withValues(alpha: 0.15));
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
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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

    return vInspectorHide(
      Semantics(
        button: true,
        enabled: isEnabled,
        label: semanticLabel ?? label,
        child: buttonWidget,
      ),
    );
  }
}

/// Link-styled control: no Material splash/padding; underline tracks text width.
final class _VButtonLink extends StatefulWidget {
  const _VButtonLink({
    required this.label,
    required this.onPressed,
    required this.isEnabled,
    required this.showLoading,
    required this.textStyle,
    this.leadingIcon,
    this.trailingIcon,
    this.foregroundColor,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool showLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final TextStyle textStyle;
  final Color? foregroundColor;
  final String? semanticLabel;

  @override
  State<_VButtonLink> createState() => _VButtonLinkState();
}

final class _VButtonLinkState extends State<_VButtonLink> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _showUnderline => widget.isEnabled && (_hovered || _focused || _pressed);

  Color _resolveForeground(BuildContext context) {
    final colors = context.vColors;
    if (!widget.isEnabled) return colors.textMuted;
    return widget.foregroundColor ?? colors.primary;
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final fg = _resolveForeground(context);
    final labelStyle = widget.textStyle.copyWith(
      color: fg,
      decoration: _showUnderline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: fg,
    );

    final content = IconTheme(
      data: IconThemeData(color: fg, size: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
            const VGap.horizontalSm(),
          ] else if (widget.leadingIcon != null) ...[
            widget.leadingIcon!,
            const VGap.horizontalSm(),
          ],
          VText(widget.label, style: labelStyle, maxLines: 1),
          if (!widget.showLoading && widget.trailingIcon != null) ...[
            const VGap.horizontalSm(),
            widget.trailingIcon!,
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: FocusableActionDetector(
        enabled: widget.isEnabled,
        mouseCursor: widget.isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (show) {
          if (_hovered == show) return;
          setState(() => _hovered = show);
        },
        onShowFocusHighlight: (show) {
          if (_focused == show) return;
          setState(() => _focused = show);
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.isEnabled ? (_) => _setPressed(true) : null,
          onTapUp: widget.isEnabled ? (_) => _setPressed(false) : null,
          onTapCancel: widget.isEnabled ? () => _setPressed(false) : null,
          onTap: widget.isEnabled ? widget.onPressed : null,
          child: Align(
            alignment: Alignment.center,
            widthFactor: 1,
            heightFactor: 1,
            child: content,
          ),
        ),
      ),
    );
  }
}
