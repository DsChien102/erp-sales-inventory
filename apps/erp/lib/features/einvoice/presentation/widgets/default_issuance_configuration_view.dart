import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/default_issuance_configuration_copy.dart';
import 'package:erp/features/einvoice/logic/default_issuance_configuration_cubit.dart';
import 'package:erp/features/einvoice/logic/default_issuance_configuration_state.dart';
import 'package:erp/features/einvoice/logic/einvoice_configuration_display.dart';
import 'package:erp/features/einvoice/presentation/support/einvoice_datetime_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/configuration_editor_bottom_bar.dart';
import 'package:erp/features/einvoice/presentation/widgets/configuration_query_failure_view.dart';
import 'package:erp/features/einvoice/presentation/widgets/settings_info_row.dart';

class DefaultIssuanceConfigurationView extends StatelessWidget {
  const DefaultIssuanceConfigurationView({
    super.key,
    this.onCancel,
    this.onBack,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DefaultIssuanceConfigurationCubit, DefaultIssuanceConfigurationState>(
      builder: (context, state) {
        return switch (state) {
          DefaultIssuanceConfigurationInitial() ||
          DefaultIssuanceConfigurationLoading() =>
            const Center(child: VLoading()),
          DefaultIssuanceConfigurationError(:final failure) =>
            ConfigurationQueryFailureView(
              failure: failure,
              onBack: onBack,
              onRetry: () =>
                  context.read<DefaultIssuanceConfigurationCubit>().load(),
            ),
          DefaultIssuanceConfigurationLoaded() => _DefaultIssuanceBody(
              state: state,
              onCancel: onCancel,
            ),
        };
      },
    );
  }
}

class _DefaultIssuanceBody extends StatelessWidget {
  const _DefaultIssuanceBody({
    required this.state,
    this.onCancel,
  });

  final DefaultIssuanceConfigurationLoaded state;
  final VoidCallback? onCancel;

  Future<void> _save(BuildContext context) async {
    final cubit = context.read<DefaultIssuanceConfigurationCubit>();
    final result = await cubit.save();
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case DefaultIssuanceSaveResult.saved:
        VToast.show(
          context,
          title: DefaultIssuanceConfigurationCopy.saveSuccessTitle,
          message: DefaultIssuanceConfigurationCopy.saveSuccessMessage,
          type: VToastType.success,
        );
      case DefaultIssuanceSaveResult.incompatible:
        VToast.show(
          context,
          title: DefaultIssuanceConfigurationCopy.incompatibleTitle,
          message: DefaultIssuanceConfigurationCopy.incompatibleMessage,
          type: VToastType.danger,
        );
      case DefaultIssuanceSaveResult.notConnected:
        VToast.show(
          context,
          title: DefaultIssuanceConfigurationCopy.notConnectedTitle,
          message: DefaultIssuanceConfigurationCopy.notConnectedMessage,
          type: VToastType.danger,
        );
      case DefaultIssuanceSaveResult.failed:
        VToast.show(
          context,
          title: DefaultIssuanceConfigurationCopy.saveErrorTitle,
          message: DefaultIssuanceConfigurationCopy.saveErrorMessage,
          type: VToastType.danger,
        );
      case DefaultIssuanceSaveResult.validationFailed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<DefaultIssuanceConfigurationCubit>();
    final selected = state.selectedTemplate;

    return Column(
      children: [
        Expanded(
          child: VPagePadding(
            vertical: VSpacing.space4,
            child: ListView(
              children: [
                VText(
                  DefaultIssuanceConfigurationCopy.introText,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textSecondary,
                ),
                const VGap.md(),
                VSelect<String>(
                  key: const Key('wgt_e01_u02_fr04_01'),
                  label: DefaultIssuanceConfigurationCopy.templateLabel,
                  hintText: DefaultIssuanceConfigurationCopy.templateHint,
                  isRequired: true,
                  value: state.selectedTemplateId,
                  errorText: state.templateError,
                  helperText: state.lastSyncedAt == null
                      ? null
                      : EInvoiceDateTimeCopy.syncedAt(state.lastSyncedAt!),
                  enabled: !state.isSubmitting,
                  onChanged: cubit.selectTemplate,
                  items: [
                    for (final template in state.templates)
                      DropdownMenuItem<String>(
                        value: template.templateId,
                        child: VText(_templateOptionLabel(template)),
                      ),
                  ],
                ),
                if (selected != null) ...[
                  const VGap.md(),
                  VCard(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          DefaultIssuanceConfigurationCopy.templateInfoTitle,
                          variant: VTextVariant.headingH4,
                          color: colors.textPrimary,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const VGap.sm(),
                        SettingsInfoRow(
                          label: DefaultIssuanceConfigurationCopy.symbolLabel,
                          value: selected.symbol ??
                              selected.serial ??
                              selected.templateId,
                        ),
                        const VDivider(),
                        const SettingsInfoRow(
                          label: DefaultIssuanceConfigurationCopy.authorityLabel,
                          value: EInvoiceConfigurationDisplay.authorityWithTaxCode,
                        ),
                        const VDivider(),
                        SettingsInfoRow(
                          label: DefaultIssuanceConfigurationCopy.invoiceTypeLabel,
                          value: selected.name,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ConfigurationEditorBottomBar(
          cancelLabel: DefaultIssuanceConfigurationCopy.cancelLabel,
          submitLabel: DefaultIssuanceConfigurationCopy.saveLabel,
          isLoading: state.isSubmitting,
          onCancel: onCancel,
          onSubmit: () => _save(context),
          submitKey: const Key('default_issuance_save'),
        ),
      ],
    );
  }

  String _templateOptionLabel(ProviderTemplateDto template) {
    final symbol = template.symbol?.trim();
    if (symbol != null && symbol.isNotEmpty) {
      return symbol;
    }
    return template.name;
  }
}
