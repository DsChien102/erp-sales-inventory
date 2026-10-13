import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductListSearchBar extends StatefulWidget {
  const ProductListSearchBar({
    super.key,
    required this.onSearch,
    this.onFilterPressed,
    this.activeFiltersCount = 0,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback? onFilterPressed;
  final int activeFiltersCount;

  @override
  State<ProductListSearchBar> createState() => _ProductListSearchBarState();
}

class _ProductListSearchBarState extends State<ProductListSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: VSearchBar(
              key: const Key('input_product_search'),
              controller: _controller,
              hintText: 'Tìm tên, SKU, barcode, thông tin bổ sung...',
              variant: VSearchBarVariant.outlined,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchChanged,
            ),
          ),
          if (widget.onFilterPressed != null) ...[
            const SizedBox(width: VSpacing.space2),
            _FilterButton(
              onPressed: widget.onFilterPressed!,
              activeFiltersCount: widget.activeFiltersCount,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.onPressed,
    required this.activeFiltersCount,
  });

  final VoidCallback onPressed;
  final int activeFiltersCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isActive = activeFiltersCount > 0;

    return Badge(
      isLabelVisible: isActive,
      label: VText('$activeFiltersCount'),
      backgroundColor: colors.success,
      offset: const Offset(4, -4),
      child: VIconBox(
        key: const Key('btn_filter_custom_fields'),
        icon: VIcons.tune,
        semanticLabel: 'Lọc sản phẩm',
        size: 44,
        iconSize: 20,
        backgroundColor: isActive ? colors.successBg : colors.surface,
        iconColor: isActive ? colors.success : colors.textPrimary,
        borderColor: isActive ? colors.success : colors.borderDefault,
        borderRadius: VRadius.input,
        onTap: onPressed,
      ),
    );
  }
}
