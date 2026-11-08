import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/einvoice/logic/provider_connection_copy.dart';
import 'package:erp/features/einvoice/logic/provider_connection_cubit.dart';
import 'package:erp/features/einvoice/logic/provider_connection_state.dart';
import 'package:erp/features/einvoice/presentation/support/einvoice_datetime_copy.dart';
import 'package:erp/features/einvoice/presentation/widgets/configuration_editor_bottom_bar.dart';
import 'package:erp/features/einvoice/presentation/widgets/configuration_query_failure_view.dart';
import 'package:erp/features/einvoice/presentation/widgets/disconnect_provider_sheet.dart';
import 'package:erp/features/einvoice/presentation/widgets/settings_info_row.dart';

class ProviderConnectionView extends StatelessWidget {
  const ProviderConnectionView({
    super.key,
    this.onCancel,
    this.onBack,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderConnectionCubit, ProviderConnectionState>(
      builder: (context, state) {
        return switch (state) {
          ProviderConnectionInitial() ||
          ProviderConnectionLoading() =>
            const Center(child: VLoading()),
          ProviderConnectionError(:final failure) =>
            ConfigurationQueryFailureView(
              failure: failure,
              onBack: onBack,
              onRetry: () => context.read<ProviderConnectionCubit>().load(),
            ),
          ProviderConnectionLoaded() => _ProviderConnectionBody(
              state: state,
              onCancel: onCancel,
            ),
        };
      },
    );
  }
}

class _ProviderConnectionBody extends StatelessWidget {
  const _ProviderConnectionBody({
    required this.state,
    this.onCancel,
  });

  final ProviderConnectionLoaded state;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (state.showsForm) {
      return _ProviderConnectionForm(
        state: state,
        onCancel: onCancel,
      );
    }
    return _ProviderConnectionInfo(
      state: state,
      kind: state.infoKind ?? ProviderConnectionInfoKind.connected,
    );
  }
}

class _ProviderConnectionForm extends StatefulWidget {
  const _ProviderConnectionForm({
    required this.state,
    this.onCancel,
  });

  final ProviderConnectionLoaded state;
  final VoidCallback? onCancel;

  @override
  State<_ProviderConnectionForm> createState() => _ProviderConnectionFormState();
}

class _ProviderConnectionFormState extends State<_ProviderConnectionForm> {
  late final TextEditingController _accountController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _accountController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<ProviderConnectionCubit>();
    final result = widget.state.reconnectMode
        ? await cubit.reconnect(
            account: _accountController.text,
            password: _passwordController.text,
          )
        : await cubit.connect(
            account: _accountController.text,
            password: _passwordController.text,
          );
    if (!mounted) {
      return;
    }
    switch (result) {
      case ProviderConnectionSubmitResult.verificationPending:
        break;
      case ProviderConnectionSubmitResult.connected:
        VToast.show(
          context,
          title: ProviderConnectionCopy.connectSuccessTitle,
          message: ProviderConnectionCopy.connectSuccessMessage,
          type: VToastType.success,
        );
      case ProviderConnectionSubmitResult.reconnected:
        VToast.show(
          context,
          title: ProviderConnectionCopy.reconnectSuccessTitle,
          message: ProviderConnectionCopy.reconnectSuccessMessage,
          type: VToastType.success,
        );
      case ProviderConnectionSubmitResult.authFailed:
        VToast.show(
          context,
          title: ProviderConnectionCopy.authFailedTitle,
          message: ProviderConnectionCopy.authFailedMessage,
          type: VToastType.danger,
        );
      case ProviderConnectionSubmitResult.failed:
        VToast.show(
          context,
          title: ProviderConnectionCopy.genericErrorTitle,
          message: ProviderConnectionCopy.genericErrorMessage,
          type: VToastType.danger,
        );
      case ProviderConnectionSubmitResult.validationFailed:
      case ProviderConnectionSubmitResult.disconnected:
      case ProviderConnectionSubmitResult.verified:
      case ProviderConnectionSubmitResult.unavailable:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final taxCode = widget.state.screen.legalProfile.taxCode;
    final submitLabel = widget.state.reconnectMode
        ? ProviderConnectionCopy.reconnectSubmitLabel
        : ProviderConnectionCopy.connectLabel;

    return Column(
      children: [
        Expanded(
          child: VPagePadding(
            vertical: VSpacing.space4,
            child: ListView(
              children: [
                VText(
                  ProviderConnectionCopy.sectionTitle,
                  variant: VTextVariant.headingH4,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.md(),
                VCard(
                  key: const Key('wgt_e01_u01_fr03_01'),
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    children: [
                      const SettingsInfoRow(
                        label: ProviderConnectionCopy.providerLabel,
                        value: ProviderConnectionCopy.providerValue,
                      ),
                      const VDivider(),
                      SettingsInfoRow(
                        label: ProviderConnectionCopy.taxCodeLabel,
                        value: taxCode,
                      ),
                    ],
                  ),
                ),
                const VGap.sm(),
                VText(
                  ProviderConnectionCopy.taxCodeCaption,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.md(),
                VTextField(
                  controller: _accountController,
                  label: ProviderConnectionCopy.accountLabel,
                  hintText: ProviderConnectionCopy.accountHint,
                  isRequired: true,
                  enabled: !widget.state.isSubmitting,
                  errorText: widget.state.accountError,
                ),
                const VGap.md(),
                VPasswordField(
                  controller: _passwordController,
                  label: ProviderConnectionCopy.passwordLabel,
                  hintText: ProviderConnectionCopy.passwordHint,
                  isRequired: true,
                  minLength: 1,
                  enabled: !widget.state.isSubmitting,
                  errorText: widget.state.passwordError,
                ),
                const VGap.sm(),
                VText(
                  ProviderConnectionCopy.passwordCaption,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        ConfigurationEditorBottomBar(
          cancelLabel: ProviderConnectionCopy.cancelLabel,
          submitLabel: submitLabel,
          isLoading: widget.state.isSubmitting,
          onCancel: widget.onCancel,
          onSubmit: _submit,
          submitKey: const Key('provider_connection_submit'),
        ),
      ],
    );
  }
}

/// D04-B / D04-C / D04-D — connected / pending / error info surfaces.
class _ProviderConnectionInfo extends StatelessWidget {
  const _ProviderConnectionInfo({
    required this.state,
    required this.kind,
  });

  final ProviderConnectionLoaded state;
  final ProviderConnectionInfoKind kind;

  Color? _statusColor(BuildContext context) {
    final colors = context.vColors;
    return switch (kind) {
      ProviderConnectionInfoKind.connected => colors.success,
      ProviderConnectionInfoKind.pending => colors.info,
      ProviderConnectionInfoKind.error => colors.danger,
    };
  }

  Future<void> _disconnect(BuildContext context) async {
    final cubit = context.read<ProviderConnectionCubit>();
    final confirmed = await showDisconnectProviderSheet(context);
    if (!confirmed || !context.mounted) {
      return;
    }
    final result = await cubit.disconnect();
    if (!context.mounted) {
      return;
    }
    if (result == ProviderConnectionSubmitResult.failed) {
      VToast.show(
        context,
        title: ProviderConnectionCopy.genericErrorTitle,
        message: ProviderConnectionCopy.genericErrorMessage,
        type: VToastType.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final connection = state.screen.connection;
    final lastChecked = connection.lastCheckedAt;
    final showReconnect = kind == ProviderConnectionInfoKind.error;

    return Column(
      children: [
        Expanded(
          child: VPagePadding(
            vertical: VSpacing.space4,
            child: ListView(
              children: [
                VText(
                  ProviderConnectionCopy.sectionTitle,
                  variant: VTextVariant.headingH4,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.md(),
                VCard(
                  key: Key(
                    kind == ProviderConnectionInfoKind.connected
                        ? 'wgt_e01_u01_fr02_01'
                        : 'wgt_e01_u01_fr02_${kind.name}',
                  ),
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    children: [
                      SettingsInfoRow(
                        label: ProviderConnectionCopy.statusLabel,
                        value: ProviderConnectionCopy.statusValue(
                          connection.status,
                        ),
                        valueColor: _statusColor(context),
                        trailing: kind == ProviderConnectionInfoKind.pending
                            ? VLoading(
                                size: 14.0,
                                strokeWidth: 2.0,
                                color: _statusColor(context),
                              )
                            : null,
                      ),
                      const VDivider(),
                      const SettingsInfoRow(
                        label: ProviderConnectionCopy.providerLabel,
                        value: ProviderConnectionCopy.providerValue,
                      ),
                      if (connection.maskedAccount case final account?) ...[
                        const VDivider(),
                        SettingsInfoRow(
                          label: ProviderConnectionCopy.accountInfoLabel,
                          value: account,
                        ),
                      ],
                      const VDivider(),
                      SettingsInfoRow(
                        label: ProviderConnectionCopy.taxCodeShortLabel,
                        value: state.screen.legalProfile.taxCode,
                      ),
                    ],
                  ),
                ),
                if (kind == ProviderConnectionInfoKind.pending) ...[
                  const VGap.md(),
                  const VBanner(
                    status: VBannerStatus.info,
                    title: ProviderConnectionCopy.pendingBannerTitle,
                    description: ProviderConnectionCopy.pendingBannerDescription,
                  ),
                ],
                if (kind == ProviderConnectionInfoKind.error) ...[
                  const VGap.md(),
                  const VBanner(
                    status: VBannerStatus.error,
                    title: ProviderConnectionCopy.errorBannerTitle,
                    description: ProviderConnectionCopy.errorBannerDescription,
                  ),
                ],
                if (lastChecked != null) ...[
                  const VGap.md(),
                  VText(
                    EInvoiceDateTimeCopy.updatedAt(lastChecked),
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VSpacing.space4),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(color: colors.borderDefault),
            ),
          ),
          child: SafeArea(
            top: false,
            child: showReconnect
                ? Row(
                    children: [
                      Expanded(
                        child: VButton(
                          key: const Key('provider_connection_disconnect'),
                          label: ProviderConnectionCopy.disconnectLabel,
                          variant: VButtonVariant.secondary,
                          tone: VComponentTone.danger,
                          onPressed: state.isSubmitting ? null : () => _disconnect(context),
                        ),
                      ),
                      const VGap.horizontalMd(),
                      Expanded(
                        child: VButton(
                          key: const Key('provider_connection_reconnect'),
                          label: ProviderConnectionCopy.reconnectSubmitLabel,
                          onPressed: state.isSubmitting
                              ? null
                              : () => context.read<ProviderConnectionCubit>().enterReconnectMode(),
                        ),
                      ),
                    ],
                  )
                : VButton(
                    key: const Key('provider_connection_disconnect'),
                    label: ProviderConnectionCopy.disconnectLabel,
                    variant: VButtonVariant.secondary,
                    tone: VComponentTone.danger,
                    fullWidth: true,
                    onPressed: state.isSubmitting ? null : () => _disconnect(context),
                  ),
          ),
        ),
      ],
    );
  }
}
