import 'package:erp/core/di/injection.dart';
import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/platform_tenant_repository.dart';
import '../platform_navigation.dart';
import '../../logic/platform_tenant_detail_cubit.dart';
import '../../logic/platform_tenant_detail_state.dart';
import '../models/platform_tenant_ui.dart';
import '../widgets/platform_organization_actions_sheet.dart';
import '../widgets/platform_organization_alerts.dart';
import '../widgets/platform_organization_bottom_bar.dart';
import '../widgets/platform_organization_confirm_sheet.dart';
import '../widgets/platform_organization_empty_view.dart';
import '../widgets/platform_organization_header_card.dart';
import '../widgets/platform_organization_info_card.dart';
import '../widgets/platform_organization_members_card.dart';
import '../widgets/platform_organization_owner_card.dart';

/// C2 — `/more/platform/organizations/:id`: chi tiết và thao tác vòng đời.
class PlatformOrganizationDetailPage extends StatelessWidget {
  const PlatformOrganizationDetailPage({
    super.key,
    required this.tenantId,
    this.repository,
    this.cubit,
  });

  final String tenantId;
  final PlatformTenantRepository? repository;

  /// Cho test: dùng cubit dựng sẵn thay vì tạo từ [repository].
  final PlatformTenantDetailCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final provided = cubit;
    if (provided != null) {
      return BlocProvider.value(value: provided, child: _View(tenantId: tenantId));
    }
    return BlocProvider(
      create: (_) => PlatformTenantDetailCubit(
        tenantId: tenantId,
        tenants: repository ?? getIt<PlatformTenantRepository>(),
      )..load(),
      child: _View(tenantId: tenantId),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.tenantId});

  final String tenantId;

  void _showFeedback(BuildContext context, PlatformTenantDetailState state) {
    final cubit = context.read<PlatformTenantDetailCubit>();
    final success = state.successMessage;
    final failure = state.failure;
    if (success != null) {
      VToast.show(context, title: 'Thành công', message: success, type: VToastType.success);
      cubit.clearFeedback();
    } else if (failure != null && state.status == IamLoadStatus.success) {
      VToast.show(context, title: 'Lỗi', message: failure.message, type: VToastType.danger);
      cubit.clearFeedback();
    }
  }

  void _openActions(BuildContext context, PlatformTenantDetailState state) {
    final cubit = context.read<PlatformTenantDetailCubit>();
    final detail = state.detail;
    if (detail == null) return;

    showVBottomSheet(
      context: context,
      child: PlatformOrganizationActionsSheet(
        status: detail.status,
        onSuspend: () {
          cubit.beginAction(PlatformTenantAction.suspend);
          showVBottomSheet(
            context: context,
            child: PlatformOrganizationConfirmSheet.suspend(
              onConfirm: (reason) => cubit.suspend(reason: reason ?? ''),
            ),
          );
        },
        onRestore: () {
          cubit.beginAction(PlatformTenantAction.restore);
          showVBottomSheet(
            context: context,
            child: PlatformOrganizationConfirmSheet.restore(
              onConfirm: (_) => cubit.restore(),
            ),
          );
        },
        onClose: () {
          cubit.beginAction(PlatformTenantAction.close);
          showVBottomSheet(
            context: context,
            child: PlatformOrganizationConfirmSheet.close(
              onConfirm: (reason) => cubit.closeOrganization(reason: reason ?? ''),
            ),
          );
        },
        onChangeOwner: () async {
          final changed = await context.push<bool>(
            '/more/platform/organizations/$tenantId/owner',
          );
          if (changed == true && context.mounted) {
            VToast.show(
              context,
              title: 'Thành công',
              message: 'Đã chuyển quyền sở hữu.',
              type: VToastType.success,
            );
            await cubit.load();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<PlatformTenantDetailCubit, PlatformTenantDetailState>(
      listenWhen: (previous, current) =>
          current.successMessage != null || current.failure != previous.failure,
      listener: _showFeedback,
      builder: (context, state) {
        final detail = state.detail;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: VAppBar(
            title: 'Chi tiết tổ chức',
            showBackButton: true,
            leading: IconButton(
              icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
              onPressed: () => leavePlatformPage(context),
            ),
          ),
          body: _body(context, state),
          bottomNavigationBar: detail == null || !detail.status.hasActions
              ? null
              : PlatformOrganizationBottomBar(
                  onActionTap: state.isSubmitting ? null : () => _openActions(context, state),
                ),
        );
      },
    );
  }

  Widget _body(BuildContext context, PlatformTenantDetailState state) {
    final cubit = context.read<PlatformTenantDetailCubit>();
    final detail = state.detail;

    if (detail != null) {
      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: cubit.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.screenMobile,
                vertical: VSpacing.space4,
              ),
              child: Column(
                children: [
                  PlatformOrganizationHeaderCard(detail: detail),
                  const VGap.md(),
                  PlatformOrganizationOwnerCard(detail: detail),
                  const VGap.md(),
                  PlatformOrganizationMembersCard(members: state.members),
                  const VGap.md(),
                  if (detail.status == TenantStatus.suspended ||
                      detail.status == TenantStatus.closed) ...[
                    PlatformOrganizationAlerts(status: detail.status),
                    const VGap.md(),
                  ],
                  PlatformOrganizationInfoCard(detail: detail),
                  const VGap.xl(),
                ],
              ),
            ),
          ),
          if (state.isSubmitting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      );
    }

    return switch (state.status) {
      IamLoadStatus.initial || IamLoadStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      IamLoadStatus.unauthorized => const PlatformOrganizationEmptyView(
        type: PlatformOrganizationEmptyType.unauthorized,
      ),
      _ => PlatformOrganizationEmptyView(
        type: PlatformOrganizationEmptyType.loadError,
        onAction: cubit.load,
      ),
    };
  }
}
