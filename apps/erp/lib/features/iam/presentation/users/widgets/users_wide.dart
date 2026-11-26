import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/admin_table.dart';
import '../../shared/detail_layout.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/organization_users_cubit.dart';
import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import 'user_list_card.dart';
import 'users_empty_state.dart';

class UsersWide extends StatelessWidget {
  const UsersWide({
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
    final cubit = context.read<OrganizationUsersCubit>();
    final isMemberTab = state.activeTab == OrganizationUsersTab.members;
    final chips = isMemberTab
        ? const ['Tất cả', 'Hoạt động', 'Tạm ngừng']
        : const ['Tất cả', 'Đang chờ', 'Hết hạn'];

    final columns = isMemberTab
        ? const [
            AdminTableColumn('Tên', flex: 2, minWidth: 260),
            AdminTableColumn('Vai trò hiện hành', flex: 1.2),
            AdminTableColumn('Trạng thái truy cập'),
            AdminTableColumn('Hoạt động gần nhất'),
          ]
        : const [
            AdminTableColumn('Email', flex: 2, minWidth: 260),
            AdminTableColumn('Vai trò ban đầu', flex: 1.2),
            AdminTableColumn('Trạng thái'),
            AdminTableColumn(''),
          ];

    final status = isMemberTab ? state.memberStatus : state.invitationStatus;
    final isLoading = status == IamLoadStatus.loading || status == IamLoadStatus.initial;
    final failure = isMemberTab ? state.memberFailure : state.invitationFailure;
    final isEmpty = isMemberTab ? state.members.isEmpty : state.invitations.isEmpty;
    final isFiltered = isMemberTab ? state.isMemberFiltered : state.isInvitationFiltered;

    Widget? tableState;
    if (!isLoading && status == IamLoadStatus.failure) {
      final isForbidden = failure?.code == IamBlockedCodes.permissionDenied;
      tableState = UsersEmptyState(
        icon: isForbidden ? VIcons.shield : VIcons.close,
        iconBgColor: isForbidden ? colors.warningBg : colors.dangerBg,
        iconColor: isForbidden ? colors.warning : colors.danger,
        title: isForbidden ? 'Bạn không có quyền quản lý' : 'Không thể tải danh sách',
        titleColor: isForbidden ? null : colors.danger,
        subtitle: isForbidden
            ? 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.'
            : (failure?.message ?? 'Đã xảy ra lỗi khi tải danh sách. Vui lòng thử lại.'),
        actionText: isForbidden ? 'Quay lại' : 'Thử lại',
        actionColor: isForbidden ? colors.success : colors.danger,
        onAction: isForbidden
            ? () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              }
            : () => cubit.refreshActiveTab(),
      );
    } else if (!isLoading && isEmpty) {
      if (isFiltered) {
        tableState = UsersEmptyState(
          icon: VIcons.search,
          title: 'Không tìm thấy kết quả',
          subtitle: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.',
          actionText: 'Xóa bộ lọc',
          actionVariant: VButtonVariant.secondary,
          onAction: onClearFilters,
        );
      } else {
        tableState = UsersEmptyState(
          icon: VIcons.info,
          title: isMemberTab ? 'Chưa có thành viên khác' : 'Chưa có lời mời nào',
          subtitle: isMemberTab
              ? 'Mời thêm người dùng để cùng vận hành tổ chức.'
              : 'Tạo lời mời mới để thêm người dùng vào tổ chức.',
          actionText: 'Mời thành viên',
          onAction: canInvite ? onInviteTap : null,
        );
      }
    }

    final rows = isMemberTab
        ? state.members.map((m) {
            final (badgeLabel, badgeTone) = memberStatusBadge(m.status);
            final lastActive = m.status == MemberStatus.active && m.lastActiveDate.isNotEmpty
                ? m.lastActiveDate
                : '—';
            return AdminTableRow(
              semanticLabel: '${m.name}, ${m.email}, ${m.role}, $badgeLabel',
              onTap: () => onMemberTap(m),
              cells: [
                Row(
                  children: [
                    DetailAvatar(userInitial(m.name), size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              VText(
                                m.name,
                                variant: VTextVariant.bodyDefault,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (m.isOwner)
                                const VBadge(
                                  label: 'Chủ sở hữu',
                                  tone: VComponentTone.primary,
                                  variant: VBadgeVariant.soft,
                                  isSmall: true,
                                ),
                            ],
                          ),
                          VText(
                            m.email,
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                VText(m.role, variant: VTextVariant.bodyDefault),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VBadge(
                    label: badgeLabel,
                    tone: badgeTone,
                    variant: VBadgeVariant.soft,
                    isSmall: true,
                  ),
                ),
                VText(
                  lastActive,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textSecondary,
                ),
              ],
            );
          }).toList()
        : state.invitations.map((i) {
            final (badgeLabel, badgeTone) = invitationStatusBadge(i.status);
            final sub = i.expiryLabel.isEmpty
                ? i.deliveryLabel
                : '${i.expiryLabel} · ${i.deliveryLabel}';
            return AdminTableRow(
              semanticLabel: '${i.email}, ${i.role}, $badgeLabel',
              onTap: () => onInvitationTap(i),
              cells: [
                Row(
                  children: [
                    DetailAvatar(invitationInitial(i.email), size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VText(
                            i.email,
                            variant: VTextVariant.bodyDefault,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          VText(
                            sub,
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                VText(i.role, variant: VTextVariant.bodyDefault),
                Align(
                  alignment: Alignment.centerLeft,
                  child: VBadge(
                    label: badgeLabel,
                    tone: badgeTone,
                    variant: VBadgeVariant.soft,
                    isSmall: true,
                  ),
                ),
                const SizedBox.shrink(),
              ],
            );
          }).toList();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              bottom: BorderSide(color: colors.borderDefault),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                // VTabsList tự vẽ gạch dưới; dịch 1 px để trùng gạch của hàng
                // công cụ (không thành hai gạch chồng — README prototype mục 41).
                child: Transform.translate(
                  offset: const Offset(0, 1),
                  child: VTabs(
                    key: const Key('users_tabs'),
                    selectedIndex: isMemberTab ? 0 : 1,
                    semanticLabel: 'Người dùng',
                    onTabSelected: onTabSelected,
                    // Tab gọn bên trái như `.t1-utools__tabs` (không giãn hết hàng).
                    child: const VTabsList(
                      isScrollable: true,
                      children: [
                        VTabsTrigger(label: 'Thành viên'),
                        VTabsTrigger(label: 'Lời mời'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 360,
                child: Row(
                  children: [
                    Expanded(
                      child: VSearchBar(
                        hintText: 'Tìm tên hoặc email',
                        controller: searchController,
                        onChanged: onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          onPressed: onOpenFilter,
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
            ],
          ),
        ),
        Expanded(
          child: AdminTablePage(
            onNearEnd: () {
              if (isMemberTab) {
                cubit.loadNextMembersPage();
              } else {
                cubit.loadNextInvitationsPage();
              }
            },
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in chips)
                    VChip(
                      label: label,
                      tone: selectedChip == label ? VComponentTone.primary : null,
                      isSelected: selectedChip == label,
                      onTap: () => onChipSelected(label),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AdminTable(
                semanticLabel: isMemberTab ? 'Thành viên' : 'Lời mời',
                columns: columns,
                rows: rows,
                loadingRows: isLoading ? 4 : 0,
                state: tableState,
              ),
              if ((isMemberTab && state.loadingMoreMembers) ||
                  (!isMemberTab && state.loadingMoreInvitations))
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: VLoading(size: 28)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
