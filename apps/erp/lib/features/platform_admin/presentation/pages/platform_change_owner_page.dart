import 'package:erp/core/di/injection.dart';
import 'package:erp/core/iam/iam_load_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';
import '../../data/platform_tenant_repository.dart';
import '../platform_navigation.dart';
import '../../logic/change_owner_cubit.dart';
import '../../logic/change_owner_state.dart';
import '../models/platform_tenant_ui.dart';
import '../widgets/platform_change_owner_confirmation_sheet.dart';
import '../widgets/platform_organization_empty_view.dart';

/// C5 — `/more/platform/organizations/:id/owner`: chọn Chủ sở hữu mới.
/// Đóng với `true` khi chuyển thành công.
class PlatformChangeOwnerPage extends StatelessWidget {
  const PlatformChangeOwnerPage({
    super.key,
    required this.tenantId,
    this.repository,
    this.cubit,
  });

  final String tenantId;
  final PlatformTenantRepository? repository;
  final ChangeOwnerCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final provided = cubit;
    if (provided != null) {
      return BlocProvider.value(value: provided, child: const _View());
    }
    return BlocProvider(
      create: (_) => ChangeOwnerCubit(
        tenantId: tenantId,
        tenants: repository ?? getIt<PlatformTenantRepository>(),
      )..load(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _confirm(BuildContext context, ChangeOwnerState state) {
    final target = state.selected;
    if (target == null) return;
    final cubit = context.read<ChangeOwnerCubit>();
    showVBottomSheet(
      context: context,
      child: PlatformChangeOwnerConfirmationSheet(
        currentOwner: state.currentOwner,
        currentOwnerName: state.detail?.ownerName ?? state.detail?.ownerEmail,
        newOwner: target,
        onConfirm: cubit.confirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<ChangeOwnerCubit>();

    return BlocConsumer<ChangeOwnerCubit, ChangeOwnerState>(
      listenWhen: (previous, current) =>
          (current.completed && !previous.completed) ||
          (current.failure != null && current.failure != previous.failure),
      listener: (context, state) {
        if (state.completed) {
          context.pop(true);
          return;
        }
        final failure = state.failure;
        if (failure != null && state.status != IamLoadStatus.failure) {
          VToast.show(context, title: 'Lỗi', message: failure.message, type: VToastType.danger);
          cubit.clearFailure();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: VAppBar(
            title: 'Thay đổi chủ sở hữu',
            showBackButton: true,
            leading: IconButton(
              icon: VIcon(icon: VIcons.arrowLeft, color: colors.textPrimary),
              onPressed: () => leavePlatformPage(context),
            ),
          ),
          body: _body(context, state, cubit),
          bottomNavigationBar: _bottomBar(context, state),
        );
      },
    );
  }

  Widget _bottomBar(BuildContext context, ChangeOwnerState state) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Hủy',
                variant: VButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => leavePlatformPage(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VButton(
                key: const Key('platform_change_owner_continue'),
                label: 'Tiếp tục',
                variant: VButtonVariant.primary,
                tone: VComponentTone.success,
                fullWidth: true,
                onPressed: state.selected != null && !state.isSubmitting
                    ? () => _confirm(context, state)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ChangeOwnerState state, ChangeOwnerCubit cubit) {
    switch (state.status) {
      case IamLoadStatus.initial:
      case IamLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case IamLoadStatus.failure:
      case IamLoadStatus.unauthorized:
        return PlatformOrganizationEmptyView(
          type: PlatformOrganizationEmptyType.loadError,
          onAction: cubit.load,
        );
      case IamLoadStatus.empty:
      case IamLoadStatus.success:
        break;
    }

    final colors = context.vColors;
    final candidates = state.candidates;
    final filtered = state.filteredCandidates;
    final owner = state.currentOwner;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VSearchBar(
            controller: _search,
            hintText: 'Tìm tên hoặc email',
            variant: VSearchBarVariant.outlined,
            onChanged: cubit.setQuery,
          ),
          const VGap.md(),
          VText(
            'Chọn thành viên đang hoạt động',
            variant: VTextVariant.headingH4,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          VText(
            'Vai trò hiện hành của thành viên sẽ được giữ nguyên.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const VGap.md(),
          if (owner != null) ...[
            _MemberCard(
              member: owner,
              note: 'Chủ sở hữu hiện tại · không chọn được',
              isSelected: false,
              onTap: null,
            ),
            const VGap.sm(),
          ],
          if (candidates.isEmpty)
            VText(
              'Chưa có thành viên đang hoạt động',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            )
          else if (filtered.isEmpty)
            VText(
              'Không tìm thấy thành viên phù hợp',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            )
          else
            for (final member in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.space3),
                child: _MemberCard(
                  member: member,
                  isSelected: member.userId == state.selectedUserId,
                  onTap: () => cubit.toggle(member.userId),
                ),
              ),
          const VGap.xl(),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isSelected,
    required this.onTap,
    this.note,
  });

  final PlatformTenantMember member;
  final bool isSelected;
  final VoidCallback? onTap;

  /// Có giá trị = thẻ bị khóa (Owner hiện tại), hiện mờ.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final disabled = onTap == null;
    final borderColor = isSelected ? colors.primary : colors.borderDefault;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('platform_owner_candidate_${member.userId}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.r16),
          child: Container(
            padding: const EdgeInsets.all(VSpacing.space4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VRadius.r16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.surfaceBrand : colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(VRadius.r12),
                  ),
                  alignment: Alignment.center,
                  child: VText(
                    initialsOf(member.displayName, fallback: 'NV'),
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        member.displayName,
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (member.email.isNotEmpty && member.fullName.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        VText(
                          member.email,
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                      const SizedBox(height: 2),
                      VText(
                        note ?? member.roleDisplay,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!disabled) _RadioCircle(isSelected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    if (isSelected) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary),
        alignment: Alignment.center,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderStrong, width: 1.5),
      ),
    );
  }
}
