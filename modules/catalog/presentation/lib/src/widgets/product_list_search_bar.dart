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
              // suffix: const _CameraIconButton(),
            ),
          ),
          if (widget.onFilterPressed != null) ...[
            const SizedBox(width: 8),
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
      label: Text('$activeFiltersCount'),
      backgroundColor: VColors.success,
      offset: const Offset(4, -4),
      child: VIconBox(
        key: const Key('btn_filter_custom_fields'),
        iconData: Icons.tune,
        size: 44,
        iconSize: 20,
        backgroundColor: isActive ? VColors.successBg : colors.surface,
        iconColor: isActive ? VColors.success : colors.textPrimary,
        borderColor: isActive ? VColors.success : colors.borderDefault,
        borderRadius: VRadius.input,
        onTap: onPressed,
      ),
    );
  }
}

// class _CameraIconButton extends StatelessWidget {
//   const _CameraIconButton();

//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: const Icon(
//         Icons.camera_alt_outlined,
//         color: VColors.textSecondary,
//       ),
//       onPressed: () {
//         // TODO: Implement barcode scan
//       },
//     );
//   }
// }
