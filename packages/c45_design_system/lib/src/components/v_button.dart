import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

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
  /// Labeled button.
  const VButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leading,
    this.trailing,
    @Deprecated('Use leading with VIcons instead') this.leadingIcon,
    @Deprecated('Use trailing with VIcons instead') this.trailingIcon,
    this.fullWidth = false,
    this.variant = VButtonVariant.primary,
    this.size = VButtonSize.medium,
    this.flexibleText = true,
    this.expandText = false,
    this.textAlign = TextAlign.center,
    this.foregroundColor,
    this.tone,
    this.emphasis = VComponentEmphasis.strong,
    this.enabled,
    this.semanticLabel,
  }) : icon = null,
       _iconOnly = false;

  /// Icon-only button (no label). [icon] is required.
  const VButton.icon({
    super.key,
    required VIcons this.icon,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
    this.variant = VButtonVariant.primary,
    this.size = VButtonSize.medium,
    this.foregroundColor,
    this.tone,
    this.emphasis = VComponentEmphasis.strong,
    this.enabled,
    this.semanticLabel,
  }) : label = '',
       leading = null,
       trailing = null,
       leadingIcon = null,
       trailingIcon = null,
       flexibleText = true,
       expandText = false,
       textAlign = TextAlign.center,
       _iconOnly = true;

  final String label;

  /// Centered icon for [VButton.icon]; null on labeled constructor.
  final VIcons? icon;

  final VoidCallback? onPressed;
  final bool isLoading;

  /// Leading icon token (canonical).
  final VIcons? leading;

  /// Trailing icon token (canonical).
  final VIcons? trailing;

  /// Deprecated: pass a raw widget. Prefer [leading].
  @Deprecated('Use leading with VIcons instead')
  final Widget? leadingIcon;

  /// Deprecated: pass a raw widget. Prefer [trailing].
  @Deprecated('Use trailing with VIcons instead')
  final Widget? trailingIcon;

  final bool fullWidth;
  final VButtonVariant variant;
  final VButtonSize size;
  final bool flexibleText;

  /// When true, the label occupies remaining width between icons ([Expanded]).
  final bool expandText;

  /// Alignment applied only to the label text slot.
  final TextAlign textAlign;

  final Color? foregroundColor;
  final VComponentTone? tone;
  final VComponentEmphasis emphasis;
  final bool? enabled;
  final String? semanticLabel;

  final bool _iconOnly;

  /// Every variant speaks the Label role (14 / 600); variants differ by fill
  /// and border, never by type size, so the primary action is never the
  /// smallest text on screen.
  static TextStyle _textStyleForVariant(VButtonVariant variant) => VTypography.actionDefault;

  static double _iconSizeFor(VButtonSize size) {
    return switch (size) {
      VButtonSize.small => 16,
      VButtonSize.medium => 18,
      VButtonSize.large => 20,
    };
  }

  Widget? _resolvedLeading(Color fg, double iconSize) {
    if (leading != null) {
      return VIcon(icon: leading, size: iconSize, color: fg);
    }
    // ignore: deprecated_member_use_from_same_package
    return leadingIcon;
  }

  Widget? _resolvedTrailing(Color fg, double iconSize) {
    if (trailing != null) {
      return VIcon(icon: trailing, size: iconSize, color: fg);
    }
    // ignore: deprecated_member_use_from_same_package
    return trailingIcon;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled =
        VComponentScope.resolveEnabled(context, local: enabled) && onPressed != null && !isLoading;
    final bool showLoading = isLoading;
    final dynamicColors = context.vColors;
    final iconSize = _iconSizeFor(size);

    if (variant == VButtonVariant.link) {
      assert(!_iconOnly, 'VButton.icon does not support VButtonVariant.link');
      return vInspectorHide(
        _VButtonLink(
          label: label,
          onPressed: onPressed,
          isEnabled: isEnabled,
          showLoading: showLoading,
          leading: leading,
          trailing: trailing,
          // ignore: deprecated_member_use_from_same_package
          leadingIcon: leadingIcon,
          // ignore: deprecated_member_use_from_same_package
          trailingIcon: trailingIcon,
          expandText: expandText,
          textAlign: textAlign,
          iconSize: iconSize,
          textStyle: _textStyleForVariant(variant),
          foregroundColor: foregroundColor,
          semanticLabel: semanticLabel,
        ),
      );
    }

    final double height;
    final EdgeInsetsGeometry padding;
    final TextStyle textStyle = _textStyleForVariant(variant);

    switch (size) {
      case VButtonSize.small:
        height = context.vDensity.controlHeightSmall;
        padding = EdgeInsets.symmetric(
          horizontal: _iconOnly ? VSpacing.space2 : VSpacing.space3,
        );
        break;
      case VButtonSize.medium:
        height = context.vDensity.controlHeightMedium;
        padding = EdgeInsets.symmetric(
          horizontal: _iconOnly ? VSpacing.space3 : VSpacing.space4,
        );
        break;
      case VButtonSize.large:
        height = context.vDensity.controlHeightLarge;
        padding = EdgeInsets.symmetric(
          horizontal: _iconOnly ? VSpacing.space4 : VSpacing.space6,
        );
        break;
    }

    final VComponentTone resolvedTone =
        VComponentScope.resolveTone(context, local: tone) ?? VComponentTone.primary;

    Color? getBgColor(Set<WidgetState> states) {
      final pressed = states.contains(WidgetState.pressed);
      final hovered = states.contains(WidgetState.hovered);

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
            return dynamicColors.surface;
          }
          if (resolvedTone == VComponentTone.warning) {
            if (pressed && hovered) return dynamicColors.warningBgPressed;
            if (pressed || hovered) return dynamicColors.warningBg;
            return dynamicColors.surface;
          }
          if (resolvedTone == VComponentTone.success) {
            if (pressed && hovered) return dynamicColors.successBgPressed;
            if (pressed || hovered) return dynamicColors.successBg;
            return dynamicColors.surface;
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
          return Colors.transparent;
      }
    }

    Color getFgColor(Set<WidgetState> states) {
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
          if (resolvedTone == VComponentTone.success) {
            return dynamicColors.success;
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
      if (variant == VButtonVariant.secondary) {
        if (resolvedTone == VComponentTone.danger) {
          return VBorders.side(dynamicColors.danger);
        }
        if (resolvedTone == VComponentTone.warning) {
          return VBorders.side(dynamicColors.warning);
        }
        if (resolvedTone == VComponentTone.success) {
          return VBorders.side(dynamicColors.success);
        }
        // Control boundary: borderInput clears 3:1 on white; hairline does not.
        return VBorders.side(dynamicColors.borderInput);
      }

      return BorderSide.none;
    }

    final enabledFg = getFgColor(const {});
    final leadingWidget = _resolvedLeading(enabledFg, iconSize);
    final trailingWidget = _resolvedTrailing(enabledFg, iconSize);

    final Widget buttonChild;
    if (_iconOnly) {
      buttonChild = showLoading
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(enabledFg),
              ),
            )
          : VIcon(icon: icon, size: iconSize, color: enabledFg);
    } else {
      final labelText = VText(
        label,
        style: textStyle.copyWith(color: enabledFg),
        textAlign: textAlign,
        overflow: expandText || !flexibleText ? TextOverflow.ellipsis : null,
        maxLines: 1,
      );

      final Widget textSlot;
      if (expandText) {
        textSlot = Expanded(child: labelText);
      } else if (flexibleText) {
        textSlot = Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: switch (textAlign) {
              TextAlign.left || TextAlign.start => Alignment.centerLeft,
              TextAlign.right || TextAlign.end => Alignment.centerRight,
              _ => Alignment.center,
            },
            child: labelText,
          ),
        );
      } else {
        textSlot = Flexible(child: labelText);
      }

      buttonChild = Row(
        mainAxisSize: expandText || fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showLoading) ...[
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(enabledFg),
              ),
            ),
            const VGap.horizontalSm(),
          ] else if (leadingWidget != null) ...[
            leadingWidget,
            const VGap.horizontalSm(),
          ],
          textSlot,
          if (!showLoading && trailingWidget != null) ...[
            const VGap.horizontalSm(),
            trailingWidget,
          ],
        ],
      );
    }

    final minWidth = _iconOnly && !fullWidth ? height : (fullWidth ? double.infinity : 0.0);

    Widget buttonWidget = TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(Size(minWidth, height)),
        fixedSize: WidgetStateProperty.all(
          Size(
            fullWidth ? double.infinity : (_iconOnly ? height : double.nan),
            height,
          ),
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
          minWidth: fullWidth
              ? double.infinity
              : (_iconOnly ? VSpacing.minTouchTarget : VSpacing.minTouchTarget),
        ),
        child: Center(
          widthFactor: fullWidth ? null : 1.0,
          heightFactor: 1.0,
          child: buttonWidget,
        ),
      );
    }

    final semanticsLabel = semanticLabel ?? (_iconOnly ? icon!.name : label);

    return vInspectorHide(
      Semantics(
        button: true,
        enabled: isEnabled,
        label: semanticsLabel,
        child: vDisabledOpacity(enabled: isEnabled, child: buttonWidget),
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
    required this.iconSize,
    required this.expandText,
    required this.textAlign,
    this.leading,
    this.trailing,
    this.leadingIcon,
    this.trailingIcon,
    this.foregroundColor,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool showLoading;
  final VIcons? leading;
  final VIcons? trailing;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool expandText;
  final TextAlign textAlign;
  final double iconSize;
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
    return widget.foregroundColor ?? colors.primary;
  }

  Widget? _leading(Color fg) {
    if (widget.leading != null) {
      return VIcon(icon: widget.leading, size: widget.iconSize, color: fg);
    }
    return widget.leadingIcon;
  }

  Widget? _trailing(Color fg) {
    if (widget.trailing != null) {
      return VIcon(icon: widget.trailing, size: widget.iconSize, color: fg);
    }
    return widget.trailingIcon;
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
    final leadingWidget = _leading(fg);
    final trailingWidget = _trailing(fg);

    final labelText = VText(
      widget.label,
      style: labelStyle,
      textAlign: widget.textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final Widget textSlot =
        widget.expandText ? Expanded(child: labelText) : Flexible(child: labelText);

    final content = Row(
      mainAxisSize: widget.expandText ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.showLoading) ...[
          SizedBox(
            width: widget.iconSize,
            height: widget.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const VGap.horizontalSm(),
        ] else if (leadingWidget != null) ...[
          leadingWidget,
          const VGap.horizontalSm(),
        ],
        textSlot,
        if (!widget.showLoading && trailingWidget != null) ...[
          const VGap.horizontalSm(),
          trailingWidget,
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: widget.semanticLabel ?? widget.label,
      onTap: widget.isEnabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: vDisabledOpacity(
          enabled: widget.isEnabled,
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
            excludeFromSemantics: true,
            onTapDown: widget.isEnabled ? (_) => _setPressed(true) : null,
            onTapUp: widget.isEnabled ? (_) => _setPressed(false) : null,
            onTapCancel: widget.isEnabled ? () => _setPressed(false) : null,
            onTap: widget.isEnabled ? widget.onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: VSpacing.minTouchTarget,
                minHeight: VSpacing.minTouchTarget,
              ),
              child: Align(
                alignment: Alignment.center,
                widthFactor: widget.expandText ? null : 1,
                heightFactor: 1,
                child: content,
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
