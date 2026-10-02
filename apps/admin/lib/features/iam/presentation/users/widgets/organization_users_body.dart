import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/organization_users_cubit.dart';
import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import 'member_filter_bottom_sheet.dart';
import 'member_list_section.dart';

/// Admin: chỉ danh sách thành viên (Membership thật). Không tab/CTA lời mời.
class OrganizationUsersBody extends StatefulWidget {
  const OrganizationUsersBody({
    super.key,
    required this.onMemberTap,
  });

  final ValueChanged<MemberUiModel> onMemberTap;

  @override
  State<OrganizationUsersBody> createState() => _OrganizationUsersBodyState();
}

class _OrganizationUsersBodyState extends State<OrganizationUsersBody> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    context.read<OrganizationUsersCubit>().setMemberSearch(value);
  }

  void _clearFilters() {
    final cubit = context.read<OrganizationUsersCubit>();
    _searchController.clear();
    cubit.setMemberSearch('');
    cubit.applyMemberCriteria(status: null, role: null, sort: null);
  }

  Future<void> _openFilterBottomSheet(BuildContext context) async {
    final cubit = context.read<OrganizationUsersCubit>();
    final currentCriteria = MemberFilterCriteria(
      status: _memberWireToChip(cubit.state.memberFilter),
      role: cubit.state.memberRoleFilter ?? 'Tất cả',
      sort: cubit.state.memberSort ?? 'Tất cả',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.vColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.sheet)),
      ),
      builder: (_) => MemberFilterBottomSheet(
        initialCriteria: currentCriteria,
        onApply: (criteria) {
          cubit.applyMemberCriteria(
            status: _memberChipToWire(criteria.status),
            role: criteria.role == 'Tất cả' ? null : criteria.role,
            sort: criteria.sort == 'Tất cả' ? null : criteria.sort,
          );
        },
      ),
    );
  }

  String? _memberChipToWire(String label) {
    return switch (label) {
      'Hoạt động' => 'active',
      'Tạm ngừng' => 'inactive',
      _ => null,
    };
  }

  String _memberWireToChip(String? wire) {
    return switch (wire) {
      'active' => 'Hoạt động',
      'inactive' => 'Tạm ngừng',
      _ => 'Tất cả',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<OrganizationUsersCubit, OrganizationUsersState>(
      builder: (context, state) {
        final selectedChip = _memberWireToChip(state.memberFilter);
        final isFilterActive =
            state.memberFilter != null ||
            (state.memberRoleFilter != null && state.memberRoleFilter != 'Tất cả') ||
            (state.memberSort != null && state.memberSort != 'Tất cả');

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Container(
                color: colors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.screenMobile,
                  vertical: VSpacing.space2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: VSearchBar(
                        hintText: 'Tìm tên hoặc email',
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const VGap.horizontalSm(),
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: isFilterActive
                            ? colors.primary.withValues(alpha: 0.1)
                            : colors.surface,
                        border: Border.all(
                          color: isFilterActive ? colors.primary : colors.borderDefault,
                        ),
                        borderRadius: BorderRadius.circular(VRadius.button),
                      ),
                      child: IconButton(
                        icon: VIcon(
                          icon: VIcons.tune,
                          size: 20,
                          color: isFilterActive ? colors.primary : colors.textPrimary,
                        ),
                        onPressed: () => _openFilterBottomSheet(context),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.borderDefault),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.screenMobile,
                  vertical: VSpacing.space3,
                ),
                child: Row(
                  children: [
                    for (final label in const [
                      'Tất cả',
                      'Hoạt động',
                      'Tạm ngừng',
                    ]) ...[
                      if (label != 'Tất cả') const VGap.horizontalSm(),
                      _FilterChip(
                        label: label,
                        selected: selectedChip == label,
                        onSelected: () {
                          context.read<OrganizationUsersCubit>().setMemberFilter(
                            _memberChipToWire(label),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: MemberListSection(
                  onMemberTap: widget.onMemberTap,
                  onClearFilters: _clearFilters,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return VChip(
      label: label,
      tone: selected ? VComponentTone.primary : null,
      onTap: onSelected,
    );
  }
}
