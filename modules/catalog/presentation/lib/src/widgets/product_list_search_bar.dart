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
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isFilterActive = widget.activeFiltersCount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: VTextField(
              key: const Key('input_product_search'),
              controller: _controller,
              hintText: 'Tìm tên, SKU, barcode, thông tin bổ sung...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () {
                  // TODO: Implement barcode scan
                },
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchChanged,
            ),
          ),
          if (widget.onFilterPressed != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              key: const Key('btn_filter_custom_fields'),
              onTap: widget.onFilterPressed,
              child: Badge(
                isLabelVisible: isFilterActive,
                label: Text('${widget.activeFiltersCount}'),
                backgroundColor: VColors.success,
                offset: const Offset(4, -4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFilterActive
                        ? VColors.successBg
                        : dynamicColors.surface,
                    borderRadius: BorderRadius.circular(VRadius.input),
                    border: Border.all(
                      color: isFilterActive
                          ? VColors.success
                          : dynamicColors.borderDefault,
                    ),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: isFilterActive
                        ? VColors.success
                        : dynamicColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
