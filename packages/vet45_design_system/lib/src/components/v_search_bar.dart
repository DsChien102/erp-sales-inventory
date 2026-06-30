import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

enum VSearchBarVariant { outlined, filled, header }

class VSearchBar extends StatefulWidget {
  final String hintText;
  final VSearchBarVariant variant;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget? suffix;

  const VSearchBar({
    super.key,
    this.hintText = 'Tìm kiếm...',
    this.variant = VSearchBarVariant.outlined,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.suffix,
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
  }

  void _handleFocusChange() {
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
  }

  @override
  void dispose() {
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

    Color bg;
    Border? border;
    Color iconColor;
    Color textColor;
    Color hintColor;

    switch (widget.variant) {
      case VSearchBarVariant.outlined:
        bg = dynamicColors.surface;
        border = Border.all(
          color: isFocused ? dynamicColors.primary : dynamicColors.borderDefault,
          width: isFocused ? 1.5 : 1,
        );
        iconColor = dynamicColors.textSecondary;
        textColor = dynamicColors.textPrimary;
        hintColor = dynamicColors.textSecondary;
        break;
      case VSearchBarVariant.filled:
        bg = VColors.neutral100;
        border = isFocused ? Border.all(color: dynamicColors.primary, width: 1.5) : null;
        iconColor = dynamicColors.textSecondary;
        textColor = dynamicColors.textPrimary;
        hintColor = dynamicColors.textSecondary;
        break;
      case VSearchBarVariant.header:
        bg = Colors.white.withValues(alpha: 0.15);
        border = isFocused ? Border.all(color: Colors.white, width: 1.5) : null;
        iconColor = Colors.white;
        textColor = Colors.white;
        hintColor = Colors.white.withValues(alpha: 0.8);
        break;
    }

    Widget content = Row(
      children: [
        Icon(Icons.search, color: iconColor, size: 20),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          child: widget.readOnly || widget.onTap != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.hintText,
                    style: VTypography.bodyDefault.copyWith(color: hintColor),
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
        if (widget.suffix != null) ...[
          const SizedBox(width: VSpacing.space2),
          widget.suffix!,
        ],
      ],
    );

    return Container(
      height: 44,
      padding: EdgeInsets.only(
        left: VSpacing.space4,
        right: widget.suffix != null ? 4.0 : VSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(VRadius.searchBar),
        border: border,
      ),
      child: widget.onTap != null
          ? InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(VRadius.searchBar),
              child: content,
            )
          : content,
    );
  }
}
