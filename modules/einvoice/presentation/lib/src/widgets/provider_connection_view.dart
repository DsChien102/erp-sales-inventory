import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import '../bloc/provider_connection_cubit.dart';
import '../bloc/provider_connection_state.dart';
import '../support/einvoice_datetime_copy.dart';
import '../support/provider_connection_copy.dart';
import 'configuration_editor_bottom_bar.dart';
import 'configuration_query_failure_view.dart';
import 'disconnect_provider_sheet.dart';
import 'provider_connection_action_sheet.dart';
import 'settings_info_row.dart';

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
          ProviderConnectionLoading() => const Center(child: VLoading()),
          ProviderConnectionError(:final failure) => ConfigurationQueryFailureView(
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
    return _ProviderConnectionConnected(
      state: state,
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
                      Divider(
                        height: VSpacing.space4,
                        thickness: VBorders.thin,
                        color: colors.borderDefault,
                      ),
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

class _ProviderConnectionConnected extends StatelessWidget {
  const _ProviderConnectionConnected({required this.state});

  final ProviderConnectionLoaded state;

  Future<void> _openActions(BuildContext context) async {
    final cubit = context.read<ProviderConnectionCubit>();
    final action = await showProviderConnectionActionSheet(context);
    if (!context.mounted || action == null) {
      return;
    }
    switch (action) {
      case ProviderConnectionAction.recheck:
        final result = await cubit.recheck();
        if (!context.mounted) {
          return;
        }
        switch (result) {
          case ProviderConnectionSubmitResult.verified:
            VToast.show(
              context,
              title: ProviderConnectionCopy.recheckSuccessTitle,
              message: ProviderConnectionCopy.recheckSuccessMessage,
              type: VToastType.success,
            );
          case ProviderConnectionSubmitResult.unavailable:
            VToast.show(
              context,
              title: ProviderConnectionCopy.unavailableTitle,
              message: ProviderConnectionCopy.unavailableMessage,
              type: VToastType.danger,
            );
          case ProviderConnectionSubmitResult.failed:
            VToast.show(
              context,
              title: ProviderConnectionCopy.genericErrorTitle,
              message: ProviderConnectionCopy.genericErrorMessage,
              type: VToastType.danger,
            );
          default:
            break;
        }
      case ProviderConnectionAction.reconnect:
        cubit.enterReconnectMode();
      case ProviderConnectionAction.disconnect:
        final confirmed = await showDisconnectProviderSheet(context);
        if (!confirmed || !context.mounted) {
          return;
        }
        final result = await cubit.disconnect();
        if (!context.mounted) {
          return;
        }
        if (result == ProviderConnectionSubmitResult.disconnected) {
          VToast.show(
            context,
            title: ProviderConnectionCopy.disconnectSuccessTitle,
            message: ProviderConnectionCopy.disconnectSuccessMessage,
            type: VToastType.success,
          );
        } else if (result == ProviderConnectionSubmitResult.failed) {
          VToast.show(
            context,
            title: ProviderConnectionCopy.genericErrorTitle,
            message: ProviderConnectionCopy.genericErrorMessage,
            type: VToastType.danger,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final connection = state.screen.connection;
    final lastChecked = connection.lastCheckedAt;

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
                  key: const Key('wgt_e01_u01_fr02_01'),
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    children: [
                      SettingsInfoRow(
                        label: ProviderConnectionCopy.statusLabel,
                        value: ProviderConnectionCopy.statusValue(
                          connection.status,
                        ),
                        valueColor:
                            connection.status == ProviderConnectionStatus.connected
                            ? colors.success
                            : null,
                      ),
                      const SettingsInfoRow(
                        label: ProviderConnectionCopy.providerLabel,
                        value: ProviderConnectionCopy.providerValue,
                      ),
                      const SettingsInfoRow(
                        label: ProviderConnectionCopy.accountInfoLabel,
                        value: ProviderConnectionCopy.displayAccount,
                      ),
                      SettingsInfoRow(
                        label: ProviderConnectionCopy.taxCodeShortLabel,
                        value: state.screen.legalProfile.taxCode,
                      ),
                    ],
                  ),
                ),
                if (lastChecked != null) ...[
                  const VGap.md(),
                  VText(
                    EInvoiceDateTimeCopy.checkedAt(lastChecked),
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
            child: VButton(
              key: const Key('provider_connection_actions'),
              label: ProviderConnectionCopy.actionsLabel,
              trailingIcon: VIcon(
                icon: VIcons.chevronUp,
                size: 20,
                color: colors.textInverse,
              ),
              onPressed: state.isSubmitting ? null : () => _openActions(context),
            ),
          ),
        ),
      ],
    );
  }
}
