import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_list_cubit.dart';
import '../bloc/partner_list_state.dart';
import '../models/partner_filter_counts.dart';
import 'partner_filter_dialog.dart';

class PartnerSearchBar extends StatefulWidget {
  const PartnerSearchBar({super.key});

  @override
  State<PartnerSearchBar> createState() => _PartnerSearchBarState();
}

class _PartnerSearchBarState extends State<PartnerSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isOpeningFilterSheet = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _activeFilterCount(PartnerListState state) {
    var count = 0;
    if (state.filterRole != null) {
      count++;
    }
    if (state.filterProfileType != null) {
      count++;
    }
    if (state.filterStatus != null && state.filterStatus != 'Đang hoạt động') {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Container(
      color: dynamicColors.surface,
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Row(
        children: [
          Expanded(
            child: VTextField(
              controller: _searchController,
              hintText: 'Tìm tên, SĐT, email, MST',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        context.read<PartnerListCubit>().search('');
                        setState(() {});
                      },
                    )
                  : null,
              onChanged: (query) {
                context.read<PartnerListCubit>().search(query);
                setState(() {});
              },
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.input),
                borderSide: BorderSide(color: dynamicColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.input),
                borderSide: BorderSide(color: dynamicColors.primary),
              ),
            ),
          ),
          const SizedBox(width: VSpacing.space2),
          BlocBuilder<PartnerListCubit, PartnerListState>(
            builder: (context, state) {
              final activeFilters = _activeFilterCount(state);
              final isFilterActive = activeFilters > 0;

              return GestureDetector(
                onTap: () => _openFilterSheet(context, state),
                child: Badge(
                  isLabelVisible: isFilterActive,
                  label: Text('$activeFilters'),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    PartnerListState state,
  ) async {
    if (_isOpeningFilterSheet) return;
    setState(() {
      _isOpeningFilterSheet = true;
    });

    final cubit = context.read<PartnerListCubit>();
    PartnerFilterCounts counts = const PartnerFilterCounts();

    try {
      counts = await cubit.fetchFilterCounts();
    } catch (_) {
      // Giữ counts = 0 nếu không tải được facet.
    }

    if (!mounted) return;
    setState(() {
      _isOpeningFilterSheet = false;
    });

    if (!context.mounted) {
      return;
    }

    final result = await showModalBottomSheet<PartnerFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerFilterDialog(
        initialRole: state.filterRole,
        initialProfileType: state.filterProfileType,
        initialStatus: state.filterStatus,
        counts: counts,
      ),
    );

    if (result != null) {
      cubit.updateFilter(
        role: result.role,
        profileType: result.profileType,
        status: result.status,
      );
    }
  }
}
