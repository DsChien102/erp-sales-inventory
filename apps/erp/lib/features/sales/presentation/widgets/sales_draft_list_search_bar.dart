import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class SalesDraftListSearchBar extends StatefulWidget {
  const SalesDraftListSearchBar({
    super.key,
    required this.onSearch,
    this.initialQuery,
  });

  final ValueChanged<String> onSearch;
  final String? initialQuery;

  @override
  State<SalesDraftListSearchBar> createState() => _SalesDraftListSearchBarState();
}

class _SalesDraftListSearchBarState extends State<SalesDraftListSearchBar> {
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
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSearch(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.value = TextEditingValue.empty;
    setState(() {});
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return VSearchBar(
      key: const Key('input_sales_draft_search'),
      controller: _controller,
      hintText: 'Tìm theo khách hàng, SĐT, ghi chú',
      variant: VSearchBarVariant.outlined,
      onChanged: _onChanged,
      onSubmitted: (value) {
        _debounce?.cancel();
        widget.onSearch(value);
      },
      onClear: _clear,
    );
  }
}
