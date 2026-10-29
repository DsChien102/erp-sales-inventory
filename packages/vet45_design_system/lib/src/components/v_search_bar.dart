import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_input.dart';
import 'v_text_field_focus_ring.dart';

enum VSearchBarVariant { outlined, filled, header }

class VSearchBar extends StatefulWidget {
  final String hintText;
  final VSearchBarVariant variant;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget? suffix;
  final bool? enabled;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  const VSearchBar({
    super.key,
    this.hintText = 'Tìm kiếm...',
    this.variant = VSearchBarVariant.outlined,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.suffix,
    this.enabled,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  @override
  State<VSearchBar> createState() => _VSearchBarState();
}

class _VSearchBarState extends State<VSearchBar> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _focusNode.addListener(_handleFocusChange);
    widget.controller?.addListener(_handleControllerChange);
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _handleControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(VSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
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
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChange);
      widget.controller?.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChange);
    _focusNode.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _clear() {
    widget.controller?.value = TextEditingValue.empty;
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);
    final focused = isEnabled && _focusNode.hasFocus;
    final useDanger = widget.tone == VComponentTone.danger;
    final isHeader = widget.variant == VSearchBarVariant.header;
    final tapOnly = widget.onTap != null;

    final Color iconColor;
    final Color textColor;
    final Color? fillColor;
    switch (widget.variant) {
      case VSearchBarVariant.outlined:
        iconColor = colors.textSecondary;
        textColor = colors.textPrimary;
        fillColor = null;
      case VSearchBarVariant.filled:
        iconColor = colors.textMuted;
        textColor = colors.textPrimary;
        fillColor = colors.surfaceAlt;
      case VSearchBarVariant.header:
        iconColor = Colors.white;
        textColor = Colors.white;
        fillColor = null;
    }

    final hasText = widget.controller?.text.isNotEmpty ?? false;
    final clearButton = widget.onClear != null && hasText
        ? GestureDetector(
            onTap: _clear,
            child: VIcon(
              icon: VIcons.close,
              color: iconColor,
              size: 20,
            ),
          )
        : null;
    final effectiveSuffix = widget.suffix ?? clearButton;

    final textStyle = isHeader ? VTypography.bodyDefault.copyWith(color: textColor) : null;
    final hintColor = isHeader ? Colors.white.withValues(alpha: 0.8) : null;

    Widget field = VInput(
      controller: widget.controller,
      focusNode: _focusNode,
      hintText: widget.hintText,
      prefix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VIcon(icon: VIcons.search, color: iconColor, size: 20),
          const VGap(VSpacing.hairline, axis: .horizontal),
        ],
      ),
      suffix: effectiveSuffix,
      enabled: widget.enabled,
      readOnly: widget.readOnly || tapOnly,
      showCursor: tapOnly || widget.readOnly ? false : null,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      autofocus: widget.autofocus,
      textStyle: textStyle,
      hintColor: hintColor,
      fillColor: isHeader ? Colors.transparent : fillColor,
      border: !isHeader,
      tone: widget.tone,
      emphasis: widget.emphasis,
      padding: VInput.defaultPadding,
    );

    if (!isHeader) {
      field = VTextFieldFocusRing(
        focused: focused,
        danger: useDanger,
        child: field,
      );
    } else {
      field = DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(VRadius.input),
          border: focused ? VBorders.all(Colors.white, width: VBorders.thin) : null,
        ),
        child: field,
      );
    }

    return vInspectorHide(
      Semantics(
        textField: widget.onTap == null,
        enabled: isEnabled,
        label: widget.semanticLabel ?? widget.hintText,
        child: vDisabledOpacity(
          enabled: isEnabled,
          child: field,
        ),
      ),
    );
  }
}
