import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../bloc/organization_users_cubit.dart';
import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import 'invitation_filter_bottom_sheet.dart';
import 'invitation_list_section.dart';
import 'member_filter_bottom_sheet.dart';
import 'member_list_section.dart';

class OrganizationUsersBody extends StatefulWidget {
  const OrganizationUsersBody({
    super.key,
    required this.canInvite,
    this.selectedId,
    required this.onMemberTap,
    required this.onInvitationTap,
    required this.onInviteTap,
  });

  final bool canInvite;
  final String? selectedId;
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
      cubit.applyInvitationCriteria(
        status: null,
        sendResult: null,
        timeRange: null,
        customDateRange: null,
      );
    }
  }

  Future<void> _openFilterBottomSheet(BuildContext context) async {
    final cubit = context.read<OrganizationUsersCubit>();
    final isMemberTab = cubit.state.activeTab == OrganizationUsersTab.members;

    if (isMemberTab) {
      final currentCriteria = MemberFilterCriteria(
        status: _memberWireToChip(cubit.state.memberFilter),
        role: cubit.state.memberRoleFilter ?? 'Tất cả',
        sort: cubit.state.memberSort ?? 'Tất cả',
      );

      await showVAdaptiveSheet<void>(
        context: context,
        title: 'Bộ lọc thành viên',
        child: MemberFilterBottomSheet(
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
    } else {
      final currentCriteria = InvitationFilterCriteria(
        status: _invitationWireToChip(cubit.state.invitationFilter),
        sendResult: cubit.state.invitationSendResultFilter ?? 'Tất cả',
        timeRange: cubit.state.invitationTimeRangeFilter ?? 'Tất cả',
        customDateRange: cubit.state.invitationCustomDateRange,
      );

      await showVAdaptiveSheet<void>(
        context: context,
        title: 'Bộ lọc lời mời',
        child: InvitationFilterBottomSheet(
          initialCriteria: currentCriteria,
          onApply: (criteria) {
            cubit.applyInvitationCriteria(
              status: _invitationChipToWire(criteria.status),
              sendResult: criteria.sendResult == 'Tất cả' ? null : criteria.sendResult,
              timeRange: criteria.timeRange == 'Tất cả' ? null : criteria.timeRange,
              customDateRange: criteria.timeRange == 'Tùy chọn' ? criteria.customDateRange : null,
            );
          },
        ),
      );
    }
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
      'Hết hạn' => 'expired',
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
      'expired' => 'Hết hạn',
      'expiring' => 'Hết hạn',
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
                  (state.memberRoleFilter != null && state.memberRoleFilter != 'Tất cả') ||
                  (state.memberSort != null && state.memberSort != 'Tất cả'))
            : (state.invitationFilter != null ||
                  state.invitationSendResultFilter != null ||
                  state.invitationTimeRangeFilter != null ||
                  state.invitationCustomDateRange != null);

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
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              tooltip: isFilterActive ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc',
                              icon: VIcon(
                                icon: VIcons.tune,
                                size: 20,
                                color: colors.textPrimary,
                              ),
                              onPressed: () => _openFilterBottomSheet(context),
                            ),
                            if (isFilterActive)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: ExcludeSemantics(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  VTabs(
                    key: const Key('users_tabs'),
                    selectedIndex: isMemberTab ? 0 : 1,
                    semanticLabel: 'Người dùng',
                    onTabSelected: (index) {
                      final tab = index == 0
                          ? OrganizationUsersTab.members
                          : OrganizationUsersTab.invitations;
                      context.read<OrganizationUsersCubit>().selectTab(tab);
                      _searchController.text = index == 0
                          ? state.memberSearch
                          : state.invitationSearch;
                      if (VListDetailLayout.isSplitOf(context)) {
                        context.go('/more/users');
                      }
                    },
                    child: const VTabsList(
                      children: [
                        VTabsTrigger(label: 'Thành viên'),
                        VTabsTrigger(label: 'Lời mời'),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.borderDefault),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.screenMobile,
                      vertical: VSpacing.space3,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: isMemberTab
                          ? [
                              for (final label in const [
                                'Tất cả',
                                'Hoạt động',
                                'Tạm ngừng',
                              ]) ...[
                                if (label != 'Tất cả') const VGap.horizontalSm(),
                                VChip(
                                  label: label,
                                  tone: selectedChip == label ? VComponentTone.primary : null,
                                  isSelected: selectedChip == label,
                                  onTap: () {
                                    context.read<OrganizationUsersCubit>().setMemberFilter(
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
                                'Hết hạn',
                              ]) ...[
                                if (label != 'Tất cả') const VGap.horizontalSm(),
                                VChip(
                                  label: label,
                                  tone: selectedChip == label ? VComponentTone.primary : null,
                                  isSelected: selectedChip == label,
                                  onTap: () {
                                    context.read<OrganizationUsersCubit>().setInvitationFilter(
                                      _invitationChipToWire(label),
                                    );
                                  },
                                ),
                              ],
                            ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: isMemberTab
                        ? MemberListSection(
                            canInvite: widget.canInvite,
                            selectedId: widget.selectedId,
                            onMemberTap: widget.onMemberTap,
                            onInviteTap: widget.onInviteTap,
                            onClearFilters: _clearFilters,
                          )
                        : InvitationListSection(
                            canInvite: widget.canInvite,
                            selectedId: widget.selectedId,
                            onInvitationTap: widget.onInvitationTap,
                            onInviteTap: widget.onInviteTap,
                            onClearFilters: _clearFilters,
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
