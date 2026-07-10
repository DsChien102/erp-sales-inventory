import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerListSearchBar extends StatefulWidget {
  const PartnerListSearchBar({
    super.key,
    required this.onSearch,
  });

  final ValueChanged<String> onSearch;

  @override
  State<PartnerListSearchBar> createState() => _PartnerListSearchBarState();
}

class _PartnerListSearchBarState extends State<PartnerListSearchBar> {
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
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: VSpacing.space2),
      child: VTextField(
        key: const Key('input_partner_search'),
        controller: _controller,
        hintText: 'Tìm tên, SĐT, MST...',
        prefixIcon: const Icon(Icons.search),
        onChanged: _onSearchChanged,
      ),
    );
  }
}
