import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:admin/features/iam/presentation.dart';

import '../../../../core/di/injection.dart';
import '../bloc/platform_tenant_detail_cubit.dart';
import '../bloc/platform_tenant_detail_state.dart';

/// Admin wrapper — tenant detail via [IIamModule] (EP-02 US-06/08/09).
class PlatformTenantDetailPage extends StatelessWidget {
  const PlatformTenantDetailPage({
    super.key,
    required this.tenantId,
    this.iamModule,
    this.showSuccessToastOnBuild = false,
  });

  final String tenantId;
  final IIamModule? iamModule;
  final bool showSuccessToastOnBuild;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PlatformTenantDetailCubit(
          iamModule: iamModule ?? getIt<IIamModule>(),
          tenantId: tenantId,
        );
        cubit.load();
        return cubit;
      },
      child: _PlatformTenantDetailView(
        showSuccessToastOnBuild: showSuccessToastOnBuild,
        iamModule: iamModule,
      ),
    );
  }
}

class _PlatformTenantDetailView extends StatelessWidget {
  const _PlatformTenantDetailView({
    required this.showSuccessToastOnBuild,
    this.iamModule,
  });

  final bool showSuccessToastOnBuild;
  final IIamModule? iamModule;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformTenantDetailCubit, PlatformTenantDetailState>(
      builder: (context, state) {
        if (state.status == PlatformTenantDetailStatus.loading && state.organization == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == PlatformTenantDetailStatus.unauthorized) {
          return const Scaffold(
            body: Center(child: Text('Không có quyền xem tổ chức')),
          );
        }
        if (state.organization == null) {
          return Scaffold(
            body: Center(
              child: Text(state.errorMessage ?? 'Không tải được chi tiết'),
            ),
          );
        }

        final cubit = context.read<PlatformTenantDetailCubit>();
        final org = state.organization!;

        return OrganizationDetailPage(
          organization: org,
          showSuccessToastOnBuild: showSuccessToastOnBuild,
          onSuspendConfirmed: (reason) => cubit.suspend(reason: reason),
          onCloseConfirmed: (reason) => cubit.closeOrganization(reason: reason),
          onRestoreConfirmed: cubit.restore,
          onTransferOwnership: (newOwnerUserId) => cubit.transferOwnership(
            newOwnerUserId: newOwnerUserId,
            idempotencyKey:
                'xfer-${org.id}-$newOwnerUserId-${DateTime.now().millisecondsSinceEpoch}',
          ),
          onResendOwnerInvitation: (email) => cubit.reinviteProvisioningOwner(email: email),
          onMemberTap: (member) {
            context.pushNamed(
              'user_detail',
              pathParameters: {'userId': member.id},
            );
          },
        );
      },
    );
  }
}
