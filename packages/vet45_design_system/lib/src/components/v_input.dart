import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
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

  /// Single-line control height shared with [VTextField] / [VSelect] / [VCombobox].
  static const double controlHeight = 48;

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
    this.onTapOutside,
    this.groupId,
    this.border = true,
    this.padding = defaultPadding,
    this.invalid = false,
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

  /// Defaults to unfocusing primary focus (same as Material [TextField]).
  /// Pass a no-op to keep focus when tapping sibling controls (e.g. custom keypad).
  final TapRegionCallback? onTapOutside;

  /// Shared with ancestor [TapRegion]s so taps inside that region are not
  /// "outside" for [onTapOutside] (see [TextField.groupId]).
  final Object? groupId;
  final bool border;

  /// Content inset around prefix + text + suffix.
  final EdgeInsets padding;
  final bool invalid;

  /// When true (default), clamps height to [controlHeight].
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);
    final useDanger = widget.invalid || widget.tone == VComponentTone.danger;
    final borderWidth = VBorders.widthFor(widget.emphasis);
    final focused = isEnabled && _focusNode.hasFocus;

    final restingBorderColor = widget.invalid
        ? colors.danger
        : switch (widget.tone) {
            VComponentTone.primary => colors.primary,
            VComponentTone.danger => colors.danger,
            _ => colors.borderDefault,
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
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign,
      onSubmitted: widget.onSubmitted,
      cursorColor: useDanger ? colors.danger : colors.primary,
      style: widget.invalid ? baseTextStyle.copyWith(color: colors.danger) : baseTextStyle,
      groupId: widget.groupId ?? EditableText,
      onTapOutside: widget.onTapOutside ??
          (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
        hintStyle: baseTextStyle.copyWith(color: colors.textMuted),
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );

    field = Padding(
      padding: widget.padding,
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
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.input),
        border: widget.border
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: field,
    );

    if (widget.lockControlHeight) {
      field = ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: VInput.controlHeight,
          maxHeight: VInput.controlHeight,
        ),
        child: field,
      );
    }

    return field;
  }
}
