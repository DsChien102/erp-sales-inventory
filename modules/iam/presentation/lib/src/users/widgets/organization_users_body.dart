import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/organization_users_cubit.dart';
import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import 'invitation_list_section.dart';
import 'member_filter_bottom_sheet.dart';
import 'member_list_section.dart';

class OrganizationUsersBody extends StatefulWidget {
  const OrganizationUsersBody({
    super.key,
    required this.onMemberTap,
    required this.onInvitationTap,
    required this.onInviteTap,
  });

  final ValueChanged<MemberUiModel> onMemberTap;
  final ValueChanged<InvitationUiModel> onInvitationTap;
  final VoidCallback onInviteTap;

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
    final cubit = context.read<OrganizationUsersCubit>();
    if (cubit.state.activeTab == OrganizationUsersTab.members) {
      cubit.setMemberSearch(value);
    } else {
      cubit.setInvitationSearch(value);
    }
  }

  void _clearFilters() {
    final cubit = context.read<OrganizationUsersCubit>();
    _searchController.clear();
    if (cubit.state.activeTab == OrganizationUsersTab.members) {
      cubit.setMemberSearch('');
      cubit.applyMemberCriteria(status: null, role: null, sort: null);
    } else {
      cubit.setInvitationSearch('');
      cubit.setInvitationFilter(null);
    }
  }

  Future<void> _openFilterBottomSheet(BuildContext context) async {
    final cubit = context.read<OrganizationUsersCubit>();
    final isMemberTab = cubit.state.activeTab == OrganizationUsersTab.members;
    if (!isMemberTab) return;

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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(VRadius.sheet)),
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

  String? _invitationChipToWire(String label) {
    return switch (label) {
      'Đang chờ' => 'pending',
      'Sắp hết hạn' => 'expiring',
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

  String _invitationWireToChip(String? wire) {
    return switch (wire) {
      'pending' => 'Đang chờ',
      'expiring' => 'Sắp hết hạn',
      _ => 'Tất cả',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<OrganizationUsersCubit, OrganizationUsersState>(
      builder: (context, state) {
        final isMemberTab = state.activeTab == OrganizationUsersTab.members;
        final selectedChip = isMemberTab
            ? _memberWireToChip(state.memberFilter)
            : _invitationWireToChip(state.invitationFilter);
        final isFilterActive = isMemberTab
            ? (state.memberFilter != null ||
                (state.memberRoleFilter != null &&
                    state.memberRoleFilter != 'Tất cả') ||
                (state.memberSort != null && state.memberSort != 'Tất cả'))
            : (state.invitationFilter != null);

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Column(
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
                              color: isFilterActive
                                  ? colors.primary
                                  : colors.borderDefault,
                            ),
                            borderRadius: BorderRadius.circular(VRadius.button),
                          ),
                          child: IconButton(
                            icon: VIcon(
                              icon: VIcons.tune,
                              size: 20,
                              color: isFilterActive
                                  ? colors.primary
                                  : colors.textPrimary,
                            ),
                            onPressed: () => _openFilterBottomSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: colors.surface,
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: 'Thành viên',
                            isActive: isMemberTab,
                            onTap: () {
                              context
                                  .read<OrganizationUsersCubit>()
                                  .selectTab(OrganizationUsersTab.members);
                              _searchController.text = state.memberSearch;
                            },
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            label: 'Lời mời',
                            isActive: !isMemberTab,
                            onTap: () {
                              context
                                  .read<OrganizationUsersCubit>()
                                  .selectTab(OrganizationUsersTab.invitations);
                              _searchController.text = state.invitationSearch;
                            },
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
                      children: isMemberTab
                          ? [
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
                                    context
                                        .read<OrganizationUsersCubit>()
                                        .setMemberFilter(
                                          _memberChipToWire(label),
                                        );
                                  },
                                ),
                              ],
                            ]
                          : [
                              for (final label in const [
                                'Tất cả',
                                'Đang chờ',
                                'Sắp hết hạn',
                              ]) ...[
                                if (label != 'Tất cả') const VGap.horizontalSm(),
                                _FilterChip(
                                  label: label,
                                  selected: selectedChip == label,
                                  onSelected: () {
                                    context
                                        .read<OrganizationUsersCubit>()
                                        .setInvitationFilter(
                                          _invitationChipToWire(label),
                                        );
                                  },
                                ),
                              ],
                            ],
                    ),
                  ),
                  Expanded(
                    child: isMemberTab
                        ? MemberListSection(
                            onMemberTap: widget.onMemberTap,
                            onInviteTap: widget.onInviteTap,
                            onClearFilters: _clearFilters,
                          )
                        : InvitationListSection(
                            onInvitationTap: widget.onInvitationTap,
                            onInviteTap: widget.onInviteTap,
                            onClearFilters: _clearFilters,
                          ),
                  ),
                ],
              ),
              if (!isMemberTab)
                Positioned(
                  right: VSpacing.screenMobile,
                  bottom:
                      MediaQuery.of(context).padding.bottom + VSpacing.space4,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: widget.onInviteTap,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: VIcon(
                            icon: VIcons.add,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: VText(
          label,
          variant: VTextVariant.bodyDefault,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
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
      selected: selected,
      onTap: onSelected,
    );
  }
}
