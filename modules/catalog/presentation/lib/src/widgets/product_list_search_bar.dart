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
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: VTextField(
              key: const Key('input_product_search'),
              controller: _controller,
              hintText: 'Tìm tên, SKU, barcode...',
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  key: const Key('btn_filter_custom_fields'),
                  icon: Icon(
                    Icons.filter_alt_outlined,
                    color: widget.activeFiltersCount > 0 ? colors.primary : colors.textSecondary,
                  ),
                  onPressed: widget.onFilterPressed,
                ),
                if (widget.activeFiltersCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.activeFiltersCount}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
