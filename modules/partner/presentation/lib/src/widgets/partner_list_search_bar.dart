import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerListSearchBar extends StatefulWidget {
  const PartnerListSearchBar({
    super.key,
    required this.onSearch,
    this.onFilterTap,
    this.activeFilterCount = 0,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;

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
      child: Row(
        children: [
          Expanded(
            child: VTextField(
              key: const Key('input_partner_search'),
              controller: _controller,
              hintText: 'Tìm tên, SĐT, email, MST...',
              prefixIcon: const Icon(Icons.search),
              onChanged: _onSearchChanged,
            ),
          ),
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: VSpacing.space3),
            InkWell(
              onTap: widget.onFilterTap,
              borderRadius: BorderRadius.circular(VRadius.button),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.activeFilterCount > 0
                          ? context.vColors.primary.withValues(alpha: 0.1)
                          : context.vColors.surface,
                      border: Border.all(
                        color: widget.activeFilterCount > 0
                            ? context.vColors.primary
                            : context.vColors.borderDefault,
                      ),
                      borderRadius: BorderRadius.circular(VRadius.button),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: widget.activeFilterCount > 0
                          ? context.vColors.primary
                          : context.vColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  if (widget.activeFilterCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.vColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.activeFilterCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

