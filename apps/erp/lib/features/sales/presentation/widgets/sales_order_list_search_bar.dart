import 'dart:async';

import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class SalesOrderListSearchBar extends StatefulWidget {
  const SalesOrderListSearchBar({
    super.key,
    required this.onSearch,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.initialQuery,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final String? initialQuery;

  @override
  State<SalesOrderListSearchBar> createState() => _SalesOrderListSearchBarState();
}

class _SalesOrderListSearchBarState extends State<SalesOrderListSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SalesOrderListSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery && widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSearch(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.value = TextEditingValue.empty;
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: VSearchBar(
            key: const Key('input_sales_order_search'),
            controller: _controller,
            hintText: 'Tìm đơn hàng, khách hàng, SĐT',
            variant: VSearchBarVariant.outlined,
            onChanged: _onSearchChanged,
            onSubmitted: (value) {
              _debounce?.cancel();
              widget.onSearch(value);
            },
            onClear: _clearSearch,
          ),
        ),
        if (widget.onFilterTap != null) ...[
          const VGap.horizontalSm(),
          _FilterButton(
            onPressed: widget.onFilterTap!,
            activeFilterCount: widget.activeFilterCount,
          ),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.onPressed,
    required this.activeFilterCount,
  });

  final VoidCallback onPressed;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isActive = activeFilterCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        VIconBox(
          key: const Key('btn_sales_order_filter'),
          icon: VIcons.tune,
          semanticLabel: 'Lọc đơn hàng',
          size: 44,
          iconSize: 20,
          backgroundColor: isActive ? colors.successBg : colors.surface,
          iconColor: isActive ? colors.success : colors.textPrimary,
          borderColor: isActive ? colors.success : colors.borderDefault,
          borderRadius: VRadius.button,
          onTap: onPressed,
        ),
        if (isActive)
          Positioned(
            right: -8,
            top: -6,
            child: VBadge(
              label: '$activeFilterCount',
              variant: VBadgeVariant.strong,
              tone: VComponentTone.success,
              isSmall: true,
            ),
          ),
      ],
    );
  }
}
