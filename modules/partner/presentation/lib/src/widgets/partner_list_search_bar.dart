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
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hasQuery = _controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: VSearchBar(
              key: const Key('input_partner_search'),
              controller: _controller,
              hintText: 'Tìm tên, SĐT, email, MST...',
              variant: VSearchBarVariant.outlined,
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                widget.onSearch(value);
              },
              suffix: hasQuery
                  ? IconButton(
                      key: const Key('btn_clear_partner_search'),
                      tooltip: 'Xóa tìm kiếm',
                      icon: VIcon(
                        iconData: Icons.close_rounded,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
          ),
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: VSpacing.space3),
            _FilterButton(
              onPressed: widget.onFilterTap!,
              activeFilterCount: widget.activeFilterCount,
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
    required this.activeFilterCount,
  });

  final VoidCallback onPressed;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isActive = activeFilterCount > 0;

    return Badge(
      isLabelVisible: isActive,
      label: Text('$activeFilterCount'),
      backgroundColor: colors.primary,
      offset: const Offset(4, -4),
      child: VIconBox(
        iconData: Icons.tune,
        size: 44,
        iconSize: 20,
        backgroundColor: isActive
            ? colors.primary.withValues(alpha: 0.1)
            : colors.surface,
        iconColor: isActive ? colors.primary : colors.textPrimary,
        borderColor: isActive ? colors.primary : colors.borderDefault,
        borderRadius: VRadius.button,
        onTap: onPressed,
      ),
    );
  }
}
