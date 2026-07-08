import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductListSearchBar extends StatefulWidget {
  const ProductListSearchBar({
    super.key,
    required this.onSearch,
  });

  final ValueChanged<String> onSearch;

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
        ],
      ),
    );
  }
}
