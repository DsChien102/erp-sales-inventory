import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:erp/features/iam/data/organization_repository.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../organizations/widgets/organization_empty_view.dart';
import '../../shared/iam_load_status.dart';
import '../../../logic/organization_profile_cubit.dart';
import '../../../logic/organization_profile_state.dart';
import '../mappers/organization_profile_ui_mapper.dart';
import '../models/organization_profile_ui_model.dart';
import '../widgets/organization_profile_actions_bottom_sheet.dart';
import '../widgets/organization_profile_narrow.dart';
import '../widgets/organization_profile_wide.dart';

/// Trang Hồ sơ tổ chức (TA-D-01 / S12).
class OrganizationProfilePage extends StatelessWidget {
  const OrganizationProfilePage({
    super.key,
    this.organizationRepository,
    this.cubit,
  });

  final OrganizationRepository? organizationRepository;
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
      organizationRepository != null,
      'OrganizationProfilePage requires organizationRepository or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationProfileCubit(
        organizationRepository: organizationRepository!,
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
    showVAdaptiveSheet(
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
                    Semantics(
                      header: true,
                      child: const VText(
                        'Không tải được hồ sơ',
                        variant: VTextVariant.headingH4,
                      ),
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
        final wide = isWideLayout(context);

        return VPageScaffold(
          title: 'Hồ sơ tổ chức',
          bottomBar: wide
              ? null
              : Padding(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  child: VButton(
                    label: 'Thao tác',
                    trailing: VIcons.chevronUp,
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.success,
                    fullWidth: true,
                    onPressed: () => _openActions(context, profile),
                  ),
                ),
          body: wide
              ? OrganizationProfileWide(
                  profile: profile,
                  onEdit: () => _openEdit(context),
                  onLegal: () => _openLegal(context),
                )
              : OrganizationProfileNarrow(
                  profile: profile,
                  onEdit: () => _openEdit(context),
                  onLegal: () => _openLegal(context),
                ),
        );
      },
    );
  }
}
