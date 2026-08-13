import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../primitives/v_text.dart';
import '../patterns/v_gap.dart';

enum VButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
  dangerOutline,
  warning,

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

  static TextStyle _textStyleForSize(VButtonSize size) {
    return switch (size) {
      VButtonSize.small => VTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      VButtonSize.medium => VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w600),
      VButtonSize.large => VTypography.headingH4.copyWith(fontWeight: FontWeight.w600),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedState = _resolveState();
    final bool isEnabled = resolvedState == VComponentState.enabled;
    final bool showLoading = resolvedState == VComponentState.loading || isLoading;
    final dynamicColors = context.vColors;

    if (variant == VButtonVariant.link) {
      return _VButtonLink(
        label: label,
        onPressed: onPressed,
        isEnabled: isEnabled,
        showLoading: showLoading,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
        textStyle: _textStyleForSize(size),
        foregroundColor: foregroundColor,
        semanticLabel: semanticLabel,
      );
    }

    // Size-based padding and height config
    final double height;
    final EdgeInsetsGeometry padding;
    final TextStyle textStyle;

    switch (size) {
      case VButtonSize.small:
        height = context.vDensity.controlHeightSmall;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space3);
        textStyle = _textStyleForSize(size);
        break;
      case VButtonSize.medium:
        height = context.vDensity.controlHeightMedium;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space4);
        textStyle = _textStyleForSize(size);
        break;
      case VButtonSize.large:
        height = context.vDensity.controlHeightLarge;
        padding = const EdgeInsets.symmetric(horizontal: VSpacing.space6);
        textStyle = _textStyleForSize(size);
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
        case VButtonVariant.link:
          // Unreachable: link uses `_VButtonLink` early return.
          return Colors.transparent;
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
        case VButtonVariant.link:
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
        return VBorders.side(dynamicColors.borderDefault);
      }
      if (variant == VButtonVariant.dangerOutline) {
        if (states.contains(WidgetState.disabled)) {
          return VBorders.side(dynamicColors.danger.withValues(alpha: 0.2));
        }
        return VBorders.side(dynamicColors.danger);
      }
      if (variant == VButtonVariant.danger && states.contains(WidgetState.disabled)) {
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

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      child: buttonWidget,
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
