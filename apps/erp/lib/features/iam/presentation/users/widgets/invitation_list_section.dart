import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../shared/iam_load_status.dart';
import '../bloc/organization_users_cubit.dart';
import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import 'invitation_card.dart';
import 'users_empty_state.dart';

class InvitationListSection extends StatelessWidget {
  const InvitationListSection({
    super.key,
    required this.onInvitationTap,
    required this.onInviteTap,
    required this.onClearFilters,
  });

  final ValueChanged<InvitationUiModel> onInvitationTap;
  final VoidCallback onInviteTap;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationUsersCubit, OrganizationUsersState>(
      buildWhen: (p, c) =>
          p.invitationStatus != c.invitationStatus ||
          p.invitations != c.invitations ||
          p.invitationFailure != c.invitationFailure ||
          p.loadingMoreInvitations != c.loadingMoreInvitations ||
          p.invitationSearch != c.invitationSearch ||
          p.invitationFilter != c.invitationFilter ||
          p.invitationSendResultFilter != c.invitationSendResultFilter ||
          p.invitationTimeRangeFilter != c.invitationTimeRangeFilter ||
          p.invitationCustomDateRange != c.invitationCustomDateRange ||
          p.invitationNextCursor != c.invitationNextCursor,
      builder: (context, state) {
        final colors = context.vColors;
        final cubit = context.read<OrganizationUsersCubit>();
        final isFiltered = state.isInvitationFiltered;

        if (state.invitationStatus == IamLoadStatus.loading ||
            state.invitationStatus == IamLoadStatus.initial) {
          return const Center(child: VLoading(size: 40));
        }

        if (state.invitationStatus == IamLoadStatus.failure) {
          final isForbidden =
              state.invitationFailure?.code == IamBlockedCodes.permissionDenied;
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
                  : (state.invitationFailure?.message ??
                      'Đã xảy ra lỗi khi tải lời mời. Vui lòng thử lại.'),
              actionText: isForbidden ? 'Quay lại' : 'Thử lại',
              actionColor: isForbidden ? colors.success : colors.danger,
              onAction: isForbidden
                  ? () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    }
                  : () => cubit.loadInvitations(reset: true),
            ),
          );
        }

        if (state.invitations.isEmpty) {
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
              title: 'Chưa có lời mời',
              subtitle: 'Mời thành viên mới để họ nhận email tham gia.',
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
                  state.hasMoreInvitations &&
                  !state.loadingMoreInvitations) {
                cubit.loadNextInvitationsPage();
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
              itemCount: state.invitations.length +
                  (state.loadingMoreInvitations ? 1 : 0),
              separatorBuilder: (_, _) => const VGap.sm(),
              itemBuilder: (context, index) {
                if (index >= state.invitations.length) {
                  return const Padding(
                    padding: EdgeInsets.all(VSpacing.space4),
                    child: Center(child: VLoading(size: 28)),
                  );
                }
                final invitation = state.invitations[index];
                return InvitationCard(
                  invitation: invitation,
                  onTap: () => onInvitationTap(invitation),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
