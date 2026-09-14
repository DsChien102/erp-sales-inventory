import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class SalesCustomerPickerSearchBar extends StatefulWidget {
  const SalesCustomerPickerSearchBar({
    super.key,
    required this.onSearch,
    this.initialQuery,
  });

  final ValueChanged<String> onSearch;
  final String? initialQuery;

  @override
  State<SalesCustomerPickerSearchBar> createState() => _SalesCustomerPickerSearchBarState();
}

class _SalesCustomerPickerSearchBarState extends State<SalesCustomerPickerSearchBar> {
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return VSearchBar(
      key: const Key('input_sg04_customer_search'),
      controller: _controller,
      hintText: 'Tìm tên, SĐT hoặc mã KH',
      variant: VSearchBarVariant.outlined,
      onChanged: (value) {
        setState(() {});
        _onChanged(value);
      },
      onSubmitted: (value) {
        _debounce?.cancel();
        widget.onSearch(value);
      },
      onClear: _clear,
    );
  }
}
