import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/einvoice/logic/automation_policy_cubit.dart';
import 'package:erp/features/einvoice/logic/automation_policy_state.dart';
import 'package:erp/features/einvoice/presentation/support/automation_policy_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/configuration_editor_bottom_bar.dart';
import 'package:erp/features/einvoice/presentation/widgets/configuration_query_failure_view.dart';
import 'package:erp/features/einvoice/presentation/widgets/switch_setting_row.dart';

class AutomationPolicyView extends StatelessWidget {
  const AutomationPolicyView({
    super.key,
    this.onCancel,
    this.onBack,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AutomationPolicyCubit, AutomationPolicyState>(
      builder: (context, state) {
        return switch (state) {
          AutomationPolicyInitial() ||
          AutomationPolicyLoading() =>
            const Center(child: VLoading()),
          AutomationPolicyError(:final failure) =>
            ConfigurationQueryFailureView(
              failure: failure,
              onBack: onBack,
              onRetry: () => context.read<AutomationPolicyCubit>().load(),
            ),
          AutomationPolicyLoaded() => _AutomationPolicyBody(
              state: state,
              onCancel: onCancel,
            ),
        };
      },
    );
  }
}

class _AutomationPolicyBody extends StatelessWidget {
  const _AutomationPolicyBody({
    required this.state,
    this.onCancel,
  });

  final AutomationPolicyLoaded state;
  final VoidCallback? onCancel;

  Future<void> _save(BuildContext context) async {
    final cubit = context.read<AutomationPolicyCubit>();
    final result = await cubit.save();
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case AutomationPolicySaveResult.saved:
        VToast.show(
          context,
          title: AutomationPolicyCopy.saveSuccessTitle,
          message: AutomationPolicyCopy.saveSuccessMessage,
          type: VToastType.success,
        );
      case AutomationPolicySaveResult.notReady:
        VToast.show(
          context,
          title: AutomationPolicyCopy.notReadyTitle,
          message: AutomationPolicyCopy.notReadyMessage,
          type: VToastType.danger,
        );
      case AutomationPolicySaveResult.stateChanged:
        VToast.show(
          context,
          title: AutomationPolicyCopy.stateChangedTitle,
          message: AutomationPolicyCopy.stateChangedMessage,
          type: VToastType.warning,
        );
      case AutomationPolicySaveResult.failed:
        VToast.show(
          context,
          title: AutomationPolicyCopy.saveErrorTitle,
          message: AutomationPolicyCopy.saveErrorMessage,
          type: VToastType.danger,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<AutomationPolicyCubit>();

    return Column(
      children: [
        Expanded(
          child: VPagePadding(
            vertical: VSpacing.space4,
            child: ListView(
              children: [
                VCard(
                  key: const Key('wgt_e01_u03_fr02_01'),
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        AutomationPolicyCopy.sectionTitle,
                        variant: VTextVariant.headingH4,
                        color: colors.textPrimary,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const VGap.md(),
                      SwitchSettingRow(
                        label: AutomationPolicyCopy.autoIssueLabel,
                        supportingText: AutomationPolicyCopy.autoIssueSupporting,
                        value: state.autoIssueEnabled,
                        enabled: !state.isSubmitting,
                        onChanged: cubit.setAutoIssueEnabled,
                      ),
                      Divider(
                        height: VSpacing.space4,
                        thickness: VBorders.thin,
                        color: colors.borderDefault,
                      ),
                      SwitchSettingRow(
                        label: AutomationPolicyCopy.autoSendLabel,
                        supportingText: AutomationPolicyCopy.autoSendSupporting,
                        value: state.autoSendEnabled,
                        enabled: !state.isSubmitting,
                        onChanged: cubit.setAutoSendEnabled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ConfigurationEditorBottomBar(
          cancelLabel: AutomationPolicyCopy.cancelLabel,
          submitLabel: AutomationPolicyCopy.saveLabel,
          isLoading: state.isSubmitting,
          onCancel: onCancel,
          onSubmit: () => _save(context),
          submitKey: const Key('automation_policy_save'),
        ),
      ],
    );
  }
}
