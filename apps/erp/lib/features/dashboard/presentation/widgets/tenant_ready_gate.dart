import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_state.dart';
import '../../../tenant_context/presentation/tenant_context_selector.dart';

/// Gate that intercepts store tabs (except "Thêm") when the tenant session
/// is loading, blocked, or in error.
///
/// Extracted from legacy `DashboardPage._buildBody`.
class TenantReadyGate extends StatelessWidget {
  const TenantReadyGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<SessionController, SessionState>(
      builder: (context, state) {
        if (state.status == TenantLoadStatus.loading ||
            state.status == TenantLoadStatus.initial) {
          return Material(
            color: colors.background,
            child: const SafeArea(
              child: Center(
                child: VLoading(),
              ),
            ),
          );
        }

        if (state.isBlocked) {
          return Material(
            color: colors.background,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  child: OrganizationEmptyView(
                    type: state.emptyStateType ??
                        OrganizationEmptyStateType.noAuthorizedOrganizations,
                    onAction: () => openTenantContextSelector(context),
                  ),
                ),
              ),
            ),
          );
        }

        if (state.status == TenantLoadStatus.failure) {
          return Material(
            color: colors.background,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  child: OrganizationEmptyView(
                    type: OrganizationEmptyStateType.loadError,
                    onAction: () => context.read<SessionController>().bootstrap(),
                  ),
                ),
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
