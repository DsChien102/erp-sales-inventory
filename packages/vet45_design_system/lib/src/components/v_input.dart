import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_field.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

/// Package-internal text control chrome (border, fill, affix slots) over [TextField].
///
/// Does **not** paint [VTextFieldFocusRing], field shell, semantics, or disabled
/// opacity — callers compose those. Not exported from `design_system.dart`.
///
/// [padding] wraps the whole row (`prefix` + text + `suffix`). Affix widgets are
/// not inset separately — pad them yourself if needed.
///
/// For a denser control, pass a tighter [padding] (e.g. [densePadding] or
/// [EdgeInsets.zero]) and set [lockControlHeight] to false when needed.
///
/// Single-line locked height follows ambient [VDensity.controlHeightMedium]
/// (shared with [VButton] size medium, [VTextField], [VSelect], [VCombobox]).
/// It is a floor for multi-line fields and grows with the system text scale, so
/// large text and wrapped lines are never clipped.
///
/// [obscureText] always renders a single line (a multi-line obscured field
/// would assert inside [TextField]).
class VInput extends StatefulWidget {
  /// Default inset — horizontal [VSpacing.space3], vertical [VSpacing.space2].
  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(
    horizontal: VSpacing.space3,
    vertical: VSpacing.space2,
  );

  /// Compact inset — horizontal [VSpacing.space2], vertical [VSpacing.space1].
  static const EdgeInsets densePadding = EdgeInsets.symmetric(
    horizontal: VSpacing.space2,
    vertical: VSpacing.space1,
  );

  /// Gap between [prefix]/[suffix] and the text field.
  static const double affixGap = VSpacing.space1;

  const VInput({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefix,
    this.suffix,
    this.enabled,
    this.obscureText = false,
    this.readOnly = false,
    this.showCursor,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.onTapUpOutside,
    this.groupId,
    this.border = true,
    this.fillColor,
    this.hintColor,
    this.padding = defaultPadding,
    this.invalid,
    this.lockControlHeight = true,
    this.maxLines = 1,
    this.minLines,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final Widget? prefix;
  final Widget? suffix;
  final bool? enabled;
  final bool obscureText;
  final bool readOnly;
  final bool? showCursor;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  /// Called when the user taps this field (also when already focused).
  final VoidCallback? onTap;

  /// Called when a pointer down occurs outside this field's [TextFieldTapRegion].
  ///
  /// When null, records the down position for the default [onTapUpOutside]
  /// dismiss (does **not** unfocus on down, so parent-list scroll keeps focus /
  /// IME). Pass a callback to override (e.g. no-op to keep focus when tapping
  /// sibling controls such as a custom keypad).
  final TapRegionCallback? onTapOutside;

  /// Called when a pointer up occurs outside this field's [TextFieldTapRegion].
  ///
  /// When null, unfocuses if the pointer did not move beyond [kTouchSlop]
  /// (completed tap). Drag/scroll past slop keeps focus.
  final TapRegionUpCallback? onTapUpOutside;

  /// Shared with ancestor [TapRegion]s so taps inside that region are not
  /// "outside" for [onTapOutside] (see [TextField.groupId]).
  final Object? groupId;
  final bool border;

  /// Fill behind the control. Null uses ambient surface.
  final Color? fillColor;

  /// Hint text color. Null uses muted text.
  final Color? hintColor;

  /// Content inset around prefix + text + suffix.
  final EdgeInsets padding;

  /// Local invalid override. Null inherits [VField.invalid] via
  /// [VField.resolveInvalid].
  final bool? invalid;

  /// When true (default), clamps height to
  /// [VDensity.controlHeightMedium] from the ambient theme.
  final bool lockControlHeight;
  final int? maxLines;
  final int? minLines;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;

  @override
  State<VInput> createState() => _VInputState();
}

class _VInputState extends State<VInput> {
  FocusNode? _ownedFocusNode;
  // Keyed by pointer so a second finger cannot overwrite the first finger's
  // down position mid-scroll.
  final Map<int, Offset> _outsidePointerDowns = {};

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant VInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _ownedFocusNode?.removeListener(_handleFocusChange);
      if (widget.focusNode == null) {
        _ownedFocusNode ??= FocusNode();
      } else {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    // Focus can change mid-build (autofocus, route push); defer the rebuild.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  void _rememberOutsidePointerDown(PointerDownEvent event) {
    // Cancelled pointers never reach the up handler; drop stale entries.
    if (_outsidePointerDowns.length > 8) _outsidePointerDowns.clear();
    _outsidePointerDowns[event.pointer] = event.position;
  }

  void _unfocusOnOutsideTapUp(PointerUpEvent event) {
    final down = _outsidePointerDowns.remove(event.pointer);
    if (down != null && (event.position - down).distance > kTouchSlop) {
      return;
    }
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);
    final isInvalid = VField.resolveInvalid(context, local: widget.invalid);
    final useDanger = isInvalid || widget.tone == VComponentTone.danger;
    final borderWidth = VBorders.widthFor(widget.emphasis);
    final focused = isEnabled && _focusNode.hasFocus;

    final restingBorderColor = isInvalid
        ? colors.danger
        : switch (widget.tone) {
            VComponentTone.primary => colors.primary,
            VComponentTone.danger => colors.danger,
            _ => colors.borderInput,
          };
    final focusBorderColor = useDanger ? colors.danger : colors.primary;
    final borderColor = !isEnabled
        ? colors.borderDefault
        : focused
        ? focusBorderColor
        : restingBorderColor;

    final baseTextStyle =
        widget.textStyle ??
        VTypography.bodyDefault.copyWith(
          color: colors.textPrimary,
        );

    final prefix = widget.prefix;
    final suffix = widget.suffix;

    // Obscured fields are single-line; minLines must never exceed maxLines.
    final maxLines = widget.obscureText ? 1 : widget.maxLines;
    final isSingleLine = maxLines == 1;
    final minLines = isSingleLine || widget.minLines == null
        ? null
        : widget.minLines!.clamp(1, maxLines ?? widget.minLines!);

    Widget field = TextField(
      controller: widget.controller,
      enabled: isEnabled,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      cursorColor: useDanger ? colors.danger : colors.primary,
      style: isInvalid ? baseTextStyle.copyWith(color: colors.danger) : baseTextStyle,
      groupId: widget.groupId ?? EditableText,
      onTapOutside: widget.onTapOutside ?? _rememberOutsidePointerDown,
      onTapUpOutside: widget.onTapUpOutside ?? _unfocusOnOutsideTapUp,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        hintText: widget.hintText,
        hintMaxLines: isSingleLine ? 1 : null,
        hintStyle: baseTextStyle.copyWith(
          color: widget.hintColor ?? colors.textMuted,
        ),
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );

    // Height-locked: the row is centred in the control, so vertical padding
    // only squeezes affixes (e.g. a 44pt icon button) without moving the text.
    final rowPadding = widget.lockControlHeight && isSingleLine
        ? widget.padding.copyWith(top: 0, bottom: 0)
        : widget.padding;

    field = Padding(
      padding: rowPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            vInspectorShow(prefix),
            const SizedBox(width: VInput.affixGap),
          ],
          Expanded(child: field),
          if (suffix != null) ...[
            const SizedBox(width: VInput.affixGap),
            vInspectorShow(suffix),
          ],
        ],
      ),
    );

    field = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.fillColor ?? colors.surface,
        borderRadius: BorderRadius.circular(VRadius.input),
        border: widget.border ? Border.all(color: borderColor, width: borderWidth) : null,
      ),
      child: field,
    );

    if (widget.lockControlHeight) {
      final controlHeight = context.vDensity.controlHeightMedium;
      // Single line stays at control height until the text scale needs more
      // room; multi-line is only floored so wrapped lines keep their height.
      final maxHeight = isSingleLine
          ? math.max(
              controlHeight,
              MediaQuery.textScalerOf(context).scale(controlHeight),
            )
          : double.infinity;
      field = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: controlHeight,
          maxHeight: maxHeight,
        ),
        child: field,
      );
    }

    return field;
  }
}
