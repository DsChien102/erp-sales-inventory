import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import 'invitation_list_section.dart';
import 'member_list_section.dart';

class UsersNarrow extends StatelessWidget {
  const UsersNarrow({
    super.key,
    required this.state,
    required this.searchController,
    required this.isFilterActive,
    required this.selectedChip,
    required this.canInvite,
    required this.onTabSelected,
    required this.onSearchChanged,
    required this.onOpenFilter,
    required this.onChipSelected,
    required this.onMemberTap,
    required this.onInvitationTap,
    required this.onInviteTap,
    required this.onClearFilters,
  });

  final OrganizationUsersState state;
  final TextEditingController searchController;
  final bool isFilterActive;
  final String selectedChip;
  final bool canInvite;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilter;
  final ValueChanged<String> onChipSelected;
  final ValueChanged<MemberUiModel> onMemberTap;
  final ValueChanged<InvitationUiModel> onInvitationTap;
  final VoidCallback onInviteTap;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isMemberTab = state.activeTab == OrganizationUsersTab.members;
    final chips = isMemberTab
        ? const ['Tất cả', 'Hoạt động', 'Tạm ngừng']
        : const ['Tất cả', 'Đang chờ', 'Hết hạn'];

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              bottom: BorderSide(color: colors.borderDefault),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.screenMobile,
                  VSpacing.space3,
                  VSpacing.screenMobile,
                  0,
                ),
                child: VSegmentedControl(
                  key: const Key('users_tabs'),
                  segments: const ['Thành viên', 'Lời mời'],
                  selectedIndex: isMemberTab ? 0 : 1,
                  semanticLabel: 'Người dùng',
                  onChanged: onTabSelected,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.screenMobile,
                  VSpacing.space3,
                  VSpacing.space2,
                  VSpacing.space3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: VSearchBar(
                        hintText: 'Tìm tên hoặc email',
                        controller: searchController,
                        onChanged: onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: VSpacing.space1),
                    _FilterIconButton(
                      isActive: isFilterActive,
                      onPressed: onOpenFilter,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space3,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final label in chips) ...[
                    if (label != 'Tất cả') const VGap.horizontalSm(),
                    VChip(
                      label: label,
                      tone: selectedChip == label
                          ? VComponentTone.primary
                          : null,
                      isSelected: selectedChip == label,
                      onTap: () => onChipSelected(label),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: isMemberTab
              ? MemberListSection(
                  canInvite: canInvite,
                  onMemberTap: onMemberTap,
                  onInviteTap: onInviteTap,
                  onClearFilters: onClearFilters,
                )
              : InvitationListSection(
                  canInvite: canInvite,
                  onInvitationTap: onInvitationTap,
                  onInviteTap: onInviteTap,
                  onClearFilters: onClearFilters,
                ),
        ),
      ],
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.isActive,
    required this.onPressed,
  });

  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: isActive ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc',
          icon: VIcon(
            icon: VIcons.tune,
            size: 20,
            color: colors.textPrimary,
          ),
          onPressed: onPressed,
        ),
        if (isActive)
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
    );
  }
}
