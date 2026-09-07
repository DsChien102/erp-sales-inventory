import 'package:flutter/material.dart';
import '../patterns/v_gap.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../foundations/icons/v_icons.dart';
import '../foundation/v_inspector_scope.dart';

import 'v_text_field.dart';

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
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    widget.controller?.addListener(_handleControllerChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(VSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      } else {
        oldWidget.focusNode?.removeListener(_handleFocusChange);
      }
      _focusNode = widget.focusNode ?? FocusNode();
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
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      widget.focusNode?.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isFocused = _focusNode.hasFocus;
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);

    Color bg;
    Border? border;
    Color iconColor;
    Color textColor;
    Color hintColor;

    final focusBorderColor = switch (widget.tone) {
      VComponentTone.primary => dynamicColors.primary,
      VComponentTone.danger => dynamicColors.danger,
      _ => dynamicColors.primary,
    };

    final borderWidth = VBorders.widthFor(widget.emphasis);

    switch (widget.variant) {
      case VSearchBarVariant.outlined:
        bg = isEnabled ? dynamicColors.surface : dynamicColors.surfaceAlt;
        border = VBorders.all(
          isFocused ? focusBorderColor : dynamicColors.borderDefault,
          width: isFocused ? VBorders.thin : borderWidth,
        );
        iconColor = dynamicColors.textSecondary;
        textColor = dynamicColors.textPrimary;
        hintColor = dynamicColors.textSecondary;
        break;
      case VSearchBarVariant.filled:
        bg = dynamicColors.surfaceAlt;
        border = isFocused
            ? VBorders.all(dynamicColors.borderStrong, width: VBorders.thin)
            : VBorders.all(dynamicColors.borderDefault, width: VBorders.thin);
        iconColor = dynamicColors.textMuted;
        textColor = dynamicColors.textPrimary;
        hintColor = dynamicColors.textSecondary;
        break;
      case VSearchBarVariant.header:
        bg = Colors.white.withValues(alpha: 0.15);
        border = isFocused ? VBorders.all(Colors.white, width: VBorders.thin) : null;
        iconColor = Colors.white;
        textColor = Colors.white;
        hintColor = Colors.white.withValues(alpha: 0.8);
        break;
    }

    final hasText = widget.controller?.text.isNotEmpty ?? false;
    final clearButton = widget.onClear != null && hasText
        ? GestureDetector(
            onTap: () {
              if (widget.controller != null) {
                widget.controller!.value = TextEditingValue.empty;
              }
              widget.onClear?.call();
            },
            child: VIcon(
              icon: VIcons.close,
              color: iconColor,
              size: 20,
            ),
          )
        : null;
    final effectiveSuffix = widget.suffix ?? clearButton;

    Widget content = Row(
      children: [
        VIcon(icon: VIcons.search, color: iconColor, size: 20),
        const VGap(VSpacing.space2, axis: Axis.horizontal),
        Expanded(
          child: widget.readOnly || widget.onTap != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: VText(
                    widget.hintText,
                    variant: VTextVariant.bodyDefault,
                    color: hintColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : TextField(
                  controller: widget.controller,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  readOnly: widget.readOnly,
                  enabled: isEnabled,
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  style: VTypography.bodyDefault.copyWith(color: textColor),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: VTypography.bodyDefault.copyWith(
                      color: hintColor,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
        ),
        if (effectiveSuffix != null) ...[
          const SizedBox(width: VSpacing.space2),
          effectiveSuffix,
        ],
      ],
    );

    return vInspectorHide(
      Semantics(
        textField: widget.onTap == null,
        enabled: isEnabled,
        label: widget.semanticLabel ?? widget.hintText,
        child: Container(
          height: VTextField.controlHeight,
          padding: EdgeInsets.only(
            left: VSpacing.space3,
            right: effectiveSuffix != null ? VSpacing.space3 : VSpacing.space4,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(VRadius.card),
            border: border,
          ),
          child: widget.onTap != null
              ? InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(VRadius.card),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}
