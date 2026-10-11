import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../shared/iam_load_status.dart';
import '../bloc/organization_users_cubit.dart';
import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import 'member_card.dart';
import 'users_empty_state.dart';

class MemberListSection extends StatelessWidget {
  const MemberListSection({
    super.key,
    required this.onMemberTap,
    required this.onInviteTap,
    required this.onClearFilters,
  });

  final ValueChanged<MemberUiModel> onMemberTap;
  final VoidCallback onInviteTap;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationUsersCubit, OrganizationUsersState>(
      buildWhen: (p, c) =>
          p.memberStatus != c.memberStatus ||
          p.members != c.members ||
          p.memberFailure != c.memberFailure ||
          p.loadingMoreMembers != c.loadingMoreMembers ||
          p.memberSearch != c.memberSearch ||
          p.memberFilter != c.memberFilter ||
          p.memberNextCursor != c.memberNextCursor,
      builder: (context, state) {
        final colors = context.vColors;
        final cubit = context.read<OrganizationUsersCubit>();
        final isFiltered =
            state.memberSearch.trim().isNotEmpty || state.memberFilter != null;

        if (state.memberStatus == IamLoadStatus.loading ||
            state.memberStatus == IamLoadStatus.initial) {
          return const Center(child: VLoading(size: 40));
        }

        if (state.memberStatus == IamLoadStatus.failure) {
          final isForbidden =
              state.memberFailure?.code == IamBlockedCodes.permissionDenied;
          return UsersEmptyScroll(
            onRefresh: cubit.refreshActiveTab,
            child: UsersEmptyState(
              icon: isForbidden ? VIcons.shield : VIcons.close,
              iconBgColor: isForbidden ? colors.warningBg : colors.dangerBg,
              iconColor: isForbidden ? colors.warning : colors.danger,
              title: isForbidden
                  ? 'Bạn không có quyền quản lý'
                  : 'Không thể tải danh sách',
              titleColor: isForbidden ? null : colors.danger,
              subtitle: isForbidden
                  ? 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.'
                  : (state.memberFailure?.message ??
                      'Đã xảy ra lỗi khi tải thành viên. Vui lòng thử lại.'),
              actionText: isForbidden ? 'Quay lại' : 'Thử lại',
              actionColor: isForbidden ? colors.success : colors.danger,
              onAction: isForbidden
                  ? () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    }
                  : () => cubit.loadMembers(reset: true),
            ),
          );
        }

        if (state.members.isEmpty) {
          if (isFiltered) {
            return UsersEmptyScroll(
              onRefresh: cubit.refreshActiveTab,
              child: UsersEmptyState(
                icon: VIcons.search,
                title: 'Không tìm thấy kết quả',
                subtitle:
                    'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.',
                actionText: 'Xóa bộ lọc',
                onAction: onClearFilters,
              ),
            );
          }
          return UsersEmptyScroll(
            onRefresh: cubit.refreshActiveTab,
            child: UsersEmptyState(
              icon: VIcons.info,
              title: 'Chưa có thành viên khác',
              subtitle: 'Mời thêm người dùng để cùng vận hành tổ chức.',
              actionText: 'Mời thành viên',
              onAction: onInviteTap,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: cubit.refreshActiveTab,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 120 &&
                  state.hasMoreMembers &&
                  !state.loadingMoreMembers) {
                cubit.loadNextMembersPage();
              }
              return false;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: VSpacing.screenMobile,
                right: VSpacing.screenMobile,
                top: VSpacing.space2,
                bottom: VSpacing.space8,
              ),
              itemCount:
                  state.members.length + (state.loadingMoreMembers ? 1 : 0),
              separatorBuilder: (_, _) => const VGap.sm(),
              itemBuilder: (context, index) {
                if (index >= state.members.length) {
                  return const Padding(
                    padding: EdgeInsets.all(VSpacing.space4),
                    child: Center(child: VLoading(size: 28)),
                  );
                }
                final member = state.members[index];
                return MemberCard(
                  member: member,
                  onTap: () => onMemberTap(member),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
