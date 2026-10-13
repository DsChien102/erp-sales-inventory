import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class SalesProductPickerSearchBar extends StatefulWidget {
  const SalesProductPickerSearchBar({
    super.key,
    required this.onSearch,
    required this.onScanTap,
    this.initialQuery,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback onScanTap;
  final String? initialQuery;

  @override
  State<SalesProductPickerSearchBar> createState() => _SalesProductPickerSearchBarState();
}

class _SalesProductPickerSearchBarState extends State<SalesProductPickerSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSearch(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.value = TextEditingValue.empty;
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Row(
      children: [
        Expanded(
          child: VSearchBar(
            key: const Key('input_sg03_product_search'),
            controller: _controller,
            hintText: 'Tìm tên, mã hoặc barcode',
            variant: VSearchBarVariant.outlined,
            onChanged: _onChanged,
            onSubmitted: (value) {
              _debounce?.cancel();
              widget.onSearch(value);
            },
            onClear: _clear,
          ),
        ),
        const VGap.horizontalSm(),
        VIconBox(
          key: const Key('btn_sg03_scan_barcode'),
          icon: VIcons.qrCode,
          semanticLabel: 'Quét mã vạch',
          size: 44,
          iconSize: 22,
          backgroundColor: colors.surface,
          iconColor: colors.success,
          borderColor: colors.borderDefault,
          borderRadius: VRadius.button,
          onTap: widget.onScanTap,
        ),
      ],
    );
  }
}
