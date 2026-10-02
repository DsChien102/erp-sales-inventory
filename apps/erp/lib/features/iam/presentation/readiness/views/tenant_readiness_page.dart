import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../organizations/widgets/organization_empty_view.dart';
import '../../shared/iam_load_status.dart';
import '../../shared/idempotency_key_factory.dart';
import '../bloc/tenant_readiness_cubit.dart';
import '../bloc/tenant_readiness_state.dart';
import '../tenant_readiness_cta_mapper.dart';
import '../widgets/activate_tenant_bottom_sheet.dart';
import '../widgets/tenant_readiness_issue_list.dart';

/// S11 — readiness checklist + activate.
class TenantReadinessPage extends StatelessWidget {
  const TenantReadinessPage({
    super.key,
    this.iamModule,
    this.executionContext,
    this.keyFactory,
    this.cubit,
    this.canActivateTenant = true,
  });

  final IIamModule? iamModule;
  final IExecutionContext? executionContext;
  final IdempotencyKeyFactory? keyFactory;
  final TenantReadinessCubit? cubit;

  /// When false, hide activate CTA (permission gate at route/page).
  final bool canActivateTenant;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _TenantReadinessView(canActivateTenant: canActivateTenant),
      );
    }
    assert(
      iamModule != null && executionContext != null,
      'TenantReadinessPage requires iamModule + executionContext or cubit',
    );
    return BlocProvider(
      create: (_) => TenantReadinessCubit(
        iamModule: iamModule!,
        executionContext: executionContext!,
        keyFactory: keyFactory ?? const UuidIdempotencyKeyFactory(),
      )..load(),
      child: _TenantReadinessView(canActivateTenant: canActivateTenant),
    );
  }
}

class _TenantReadinessView extends StatelessWidget {
  const _TenantReadinessView({required this.canActivateTenant});

  final bool canActivateTenant;

  Future<void> _onIssueTap(
    BuildContext context,
    String issueCode,
    String? route,
  ) async {
    if (route != null) {
      await context.push(route);
      if (context.mounted) {
        await context.read<TenantReadinessCubit>().load();
      }
      return;
    }
    VToast.show(
      context,
      title: TenantReadinessCtaMapper.labelFor(issueCode),
      message: TenantReadinessCtaMapper.supportHintFor(issueCode),
      type: VToastType.warning,
    );
  }

  Future<void> _activate(BuildContext context) async {
    final cubit = context.read<TenantReadinessCubit>();
    final readiness = cubit.state.readiness;
    if (readiness == null || !cubit.state.canStartActivation) return;

    final ok = await showActivateTenantBottomSheet(
      context: context,
      readiness: readiness,
      onActivate: cubit.activate,
    );
    if (!context.mounted) return;
    if (ok == true) {
      VToast.show(
        context,
        title: 'Thành công',
        message: cubit.state.successMessage ?? 'Đã kích hoạt tổ chức.',
        type: VToastType.success,
      );
      context.go('/');
      return;
    }
    final failure = cubit.state.failure;
    if (failure != null) {
      VToast.show(
        context,
        title: 'Không kích hoạt được',
        message: failure.message,
        type: VToastType.danger,
      );
      cubit.clearFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TenantReadinessCubit, TenantReadinessState>(
      listenWhen: (prev, next) =>
          prev.successMessage != next.successMessage &&
          next.successMessage != null &&
          !next.isActivating,
      listener: (context, state) {
        // Success toast for already-active soft path (no sheet).
        if (state.activation == null && state.successMessage != null) {
          VToast.show(
            context,
            title: 'Thành công',
            message: state.successMessage!,
            type: VToastType.success,
          );
          context.read<TenantReadinessCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        if (state.status == IamLoadStatus.loading || state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Hoàn tất thiết lập',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure || state.readiness == null) {
          final isForbidden = state.failure?.code == IamBlockedCodes.permissionDenied;
          if (isForbidden) {
            return VPageScaffold(
              title: 'Hoàn tất thiết lập',
              body: OrganizationEmptyView(
                type: OrganizationEmptyStateType.unauthorized,
                onAction: () => Navigator.of(context).pop(),
              ),
            );
          }
          final colors = context.vColors;
          return VPageScaffold(
            title: 'Hoàn tất thiết lập',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VText(
                      'Không tải được readiness',
                      variant: VTextVariant.headingH4,
                    ),
                    const VGap.sm(),
                    VText(
                      state.failure?.message ?? 'Đã xảy ra lỗi',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const VGap.lg(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () => context.read<TenantReadinessCubit>().load(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final readiness = state.readiness!;
        final canStartActivation = state.canStartActivation;
        final showActivate =
            canActivateTenant &&
            canStartActivation &&
            readiness.status != TenantLifecycleStatus.active;
        final isActivationPermissionBlocked =
            canStartActivation &&
            readiness.status != TenantLifecycleStatus.active &&
            !canActivateTenant;
        final repairRoute = _firstRepairRoute(readiness);

        return VPageScaffold(
          title: 'Hoàn tất thiết lập',
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space4,
            ),
            children: [
              if (canStartActivation) ...[
                const TenantReadyToActivateCard(),
                const VGap.md(),
              ],
              TenantRequiredSetupCard(
                blockers: readiness.blockers,
              ),
              const VGap.md(),
              TenantLegalProfileInfoCard(
                isReady: canStartActivation,
              ),
            ],
          ),
          bottomBar: Padding(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            child: VButton(
              key: showActivate
                  ? const Key('btn_activate_tenant')
                  : const Key('btn_complete_tenant_setup'),
              label: showActivate
                  ? 'Kích hoạt tổ chức'
                  : isActivationPermissionBlocked
                  ? 'Không có quyền kích hoạt'
                  : 'Bổ sung thông tin tổ chức',
              fullWidth: true,
              size: VButtonSize.large,
              isLoading: showActivate && state.isActivating,
              onPressed: showActivate
                  ? state.isActivating
                        ? null
                        : () => _activate(context)
                  : isActivationPermissionBlocked
                  ? null
                  : repairRoute == null
                  ? null
                  : () => _onIssueTap(
                      context,
                      _firstRepairIssue(readiness)!,
                      repairRoute,
                    ),
            ),
          ),
        );
      },
    );
  }

  static String? _firstRepairIssue(TenantReadinessDto readiness) {
    for (final code in [...readiness.blockers, ...readiness.warnings]) {
      if (TenantReadinessCtaMapper.routeFor(code) != null) return code;
    }
    return null;
  }

  static String? _firstRepairRoute(TenantReadinessDto readiness) {
    final issueCode = _firstRepairIssue(readiness);
    return issueCode == null ? null : TenantReadinessCtaMapper.routeFor(issueCode);
  }
}
