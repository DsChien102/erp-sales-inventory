import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/einvoice_configuration_overview_cubit.dart';
import '../bloc/einvoice_configuration_overview_state.dart';
import '../support/einvoice_configuration_overview_copy.dart';
import 'configuration_query_failure_view.dart';
import 'readiness_summary.dart';
import 'settings_navigation_item.dart';

class EInvoiceConfigurationOverviewView extends StatelessWidget {
  const EInvoiceConfigurationOverviewView({
    super.key,
    this.onConnectionTap,
    this.onIssuanceTap,
    this.onAutomationTap,
    this.onBack,
  });

  final VoidCallback? onConnectionTap;
  final VoidCallback? onIssuanceTap;
  final VoidCallback? onAutomationTap;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EInvoiceConfigurationOverviewCubit, EInvoiceConfigurationOverviewState>(
      builder: (context, state) {
        return switch (state) {
          EInvoiceConfigurationOverviewInitial() ||
          EInvoiceConfigurationOverviewLoading() => const Center(child: VLoading()),
          EInvoiceConfigurationOverviewError(:final failure) => ConfigurationQueryFailureView(
            failure: failure,
            onBack: onBack,
            onRetry: () => context.read<EInvoiceConfigurationOverviewCubit>().load(),
          ),
          EInvoiceConfigurationOverviewLoaded() => _EInvoiceConfigurationOverviewBody(
            state: state,
            onConnectionTap: onConnectionTap,
            onIssuanceTap: onIssuanceTap,
            onAutomationTap: onAutomationTap,
          ),
        };
      },
    );
  }
}

class _EInvoiceConfigurationOverviewBody extends StatelessWidget {
  const _EInvoiceConfigurationOverviewBody({
    required this.state,
    this.onConnectionTap,
    this.onIssuanceTap,
    this.onAutomationTap,
  });

  final EInvoiceConfigurationOverviewLoaded state;
  final VoidCallback? onConnectionTap;
  final VoidCallback? onIssuanceTap;
  final VoidCallback? onAutomationTap;

  VoidCallback? get _completeTap {
    if (state.isReady) {
      return null;
    }
    if (state.connectionIncomplete) {
      return onConnectionTap;
    }
    if (state.issuanceIncomplete) {
      return onIssuanceTap;
    }
    return onAutomationTap;
  }

  @override
  Widget build(BuildContext context) {
    return VPagePadding(
      vertical: VSpacing.space4,
      child: ListView(
        children: [
          ReadinessSummary(
            key: Key(
              state.isReady ? 'wgt_e01_u04_fr09_02' : 'wgt_e01_u04_fr09_01',
            ),
            isReady: state.isReady,
            blockerCount: state.blockerCount,
            onCompleteTap: _completeTap,
          ),
          const VGap.md(),
          SettingsNavigationItem(
            icon: VIcons.key,
            title: EInvoiceConfigurationOverviewCopy.connectionTitle,
            subtitle: EInvoiceConfigurationOverviewCopy.connectionSubtitle(
              state.connection.status,
            ),
            onTap: onConnectionTap,
          ),
          const VGap.md(),
          SettingsNavigationItem(
            icon: VIcons.fileCheck,
            title: EInvoiceConfigurationOverviewCopy.issuanceTitle,
            subtitle: EInvoiceConfigurationOverviewCopy.issuanceSubtitle(
              profile: state.profile,
              templates: state.templates,
            ),
            onTap: onIssuanceTap,
          ),
          const VGap.md(),
          SettingsNavigationItem(
            icon: VIcons.tune,
            title: EInvoiceConfigurationOverviewCopy.automationTitle,
            subtitle: EInvoiceConfigurationOverviewCopy.automationSubtitle(
              isReady: state.isReady,
              policy: state.policy,
            ),
            onTap: onAutomationTap,
          ),
        ],
      ),
    );
  }
}
