import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../organizations/widgets/organization_empty_view.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/organization_profile_cubit.dart';
import '../bloc/organization_profile_state.dart';
import '../mappers/organization_profile_ui_mapper.dart';
import '../models/organization_profile_ui_model.dart';
import '../widgets/organization_profile_actions_bottom_sheet.dart';

/// Trang Hồ sơ tổ chức (TA-D-01 / S12).
class OrganizationProfilePage extends StatelessWidget {
  const OrganizationProfilePage({
    super.key,
    this.iamModule,
    this.executionContext,
    this.cubit,
  });

  final IIamModule? iamModule;
  final IExecutionContext? executionContext;
  final OrganizationProfileCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _OrganizationProfileView(),
      );
    }
    assert(
      iamModule != null && executionContext != null,
      'OrganizationProfilePage requires iamModule + executionContext or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationProfileCubit(
        iamModule: iamModule!,
        executionContext: executionContext!,
      )..load(),
      child: const _OrganizationProfileView(),
    );
  }
}

class _OrganizationProfileView extends StatelessWidget {
  const _OrganizationProfileView();

  Future<void> _openEdit(BuildContext context) async {
    final cubit = context.read<OrganizationProfileCubit>();
    final changed = await context.push<bool>(
      '/more/organization-profile/edit',
      extra: cubit,
    );
    if (changed == true && context.mounted) {
      await cubit.load();
    }
  }

  Future<void> _openLegal(BuildContext context) async {
    final cubit = context.read<OrganizationProfileCubit>();
    final changed = await context.push<bool>(
      '/more/organization-profile/legal',
      extra: cubit,
    );
    if (changed == true && context.mounted) {
      await cubit.load();
    }
  }

  void _openActions(
    BuildContext context,
    OrganizationProfileUiModel profile,
  ) {
    showVBottomSheet(
      context: context,
      child: OrganizationProfileActionsBottomSheet(
        hasLegalProfile: profile.hasLegalProfile,
        onEditInfoTap: () => _openEdit(context),
        onAddLegalTap: () => _openLegal(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationProfileCubit, OrganizationProfileState>(
      builder: (context, state) {
        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Hồ sơ tổ chức',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure || state.tenant == null) {
          final isForbidden =
              state.failure?.code == IamBlockedCodes.permissionDenied;
          if (isForbidden) {
            return VPageScaffold(
              title: 'Hồ sơ tổ chức',
              body: OrganizationEmptyView(
                type: OrganizationEmptyStateType.unauthorized,
                onAction: () => Navigator.of(context).pop(),
              ),
            );
          }
          final colors = context.vColors;
          return VPageScaffold(
            title: 'Hồ sơ tổ chức',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VText(
                      'Không tải được hồ sơ',
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
                      onPressed: () =>
                          context.read<OrganizationProfileCubit>().load(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = OrganizationProfileUiMapper.fromTenant(state.tenant!);
        final colors = context.vColors;
        final legal = profile.legalProfile;

        return VPageScaffold(
          title: 'Hồ sơ tổ chức',
          bottomBar: Padding(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            child: VButton(
              label: 'Thao tác',
              trailingIcon: VIcon(
                icon: VIcons.chevronUp,
                color: colors.surface,
              ),
              variant: VButtonVariant.primary,
              tone: VComponentTone.success,
              fullWidth: true,
              onPressed: () => _openActions(context, profile),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            children: [
              VCard(
                backgroundColor: colors.surface,
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Row(
                  children: [
                    VIcon(
                      icon: VIcons.apartment,
                      size: 24,
                      color: colors.textPrimary,
                    ),
                    const VGap.horizontalSm(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VText(
                            profile.name,
                            variant: VTextVariant.headingH4,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const VGap.xs(),
                          VText(
                            profile.statusDescription,
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    VBadge(
                      label: profile.statusLabel,
                      tone: VComponentTone.success,
                      variant: VBadgeVariant.soft,
                    ),
                  ],
                ),
              ),
              const VGap.sm(),
              VCard(
                backgroundColor: colors.surface,
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      'Thông tin tổ chức',
                      variant: VTextVariant.headingH4,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const VGap.md(),
                    _InfoRow(label: 'Tên hiển thị', value: profile.name),
                    const VGap.md(),
                    _InfoRow(label: 'Điện thoại', value: profile.phone),
                    const VGap.md(),
                    _InfoRow(label: 'Email', value: profile.email),
                    const VGap.md(),
                    _InfoRow(label: 'Địa chỉ', value: profile.address),
                  ],
                ),
              ),
              const VGap.sm(),
              VCard(
                backgroundColor: colors.surface,
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      'Hồ sơ pháp lý',
                      variant: VTextVariant.headingH4,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const VGap.md(),
                    if (legal == null)
                      _LegalNotice(
                        title: profile.legalNoticeTitle,
                        message: profile.legalNoticeMessage,
                      )
                    else ...[
                      _InfoRow(
                        label: 'Loại chủ thể',
                        value: legal.entityTypeLabel,
                      ),
                      const VGap.md(),
                      _InfoRow(label: 'Tên pháp lý', value: legal.legalName),
                      const VGap.md(),
                      _InfoRow(label: 'Mã số thuế', value: legal.taxCode),
                      if (legal.registeredAddress.isNotEmpty) ...[
                        const VGap.md(),
                        _InfoRow(
                          label: 'Địa chỉ đăng ký',
                          value: legal.registeredAddress,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.warningBg,
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(
            icon: VIcons.warning,
            size: 20,
            color: colors.warning,
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  title,
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.warning,
                  ),
                ),
                const VGap.xs(),
                VText(
                  message,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textMuted,
        ),
        Flexible(
          child: VText(
            value.isEmpty ? '—' : value,
            variant: VTextVariant.bodyDefault,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
