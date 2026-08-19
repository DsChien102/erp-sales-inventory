import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../support/configuration_query_failure.dart';
import 'automation_policy_state.dart';

enum AutomationPolicySaveResult {
  saved,
  notReady,
  stateChanged,
  failed,
}

final class AutomationPolicyCubit extends Cubit<AutomationPolicyState> {
  AutomationPolicyCubit({
    required IEInvoiceModule einvoiceModule,
    required IExecutionContext executionContext,
  }) : _einvoiceModule = einvoiceModule,
       _executionContext = executionContext,
       super(const AutomationPolicyInitial());

  final IEInvoiceModule _einvoiceModule;
  final IExecutionContext _executionContext;

  Future<void> load() async {
    emit(const AutomationPolicyLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final policy = await _einvoiceModule.executeQueryAsync(
        GetAutomationPolicyQuery(tenantId: tenantId, actorId: actorId),
      );
      if (isClosed) {
        return;
      }
      emit(
        AutomationPolicyLoaded(
          policy: policy,
          autoIssueEnabled: policy.autoIssueEnabled,
          autoSendEnabled: policy.autoSendEnabled,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(AutomationPolicyError(mapConfigurationQueryFailure(error)));
    }
  }

  void setAutoIssueEnabled(bool value) {
    final current = state;
    if (current is! AutomationPolicyLoaded || current.isSubmitting) {
      return;
    }
    emit(current.copyWith(autoIssueEnabled: value));
  }

  void setAutoSendEnabled(bool value) {
    final current = state;
    if (current is! AutomationPolicyLoaded || current.isSubmitting) {
      return;
    }
    emit(current.copyWith(autoSendEnabled: value));
  }

  Future<AutomationPolicySaveResult> save() async {
    final current = state;
    if (current is! AutomationPolicyLoaded) {
      return AutomationPolicySaveResult.failed;
    }

    emit(current.copyWith(isSubmitting: true));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final policy = await _einvoiceModule.executeCommandAsync(
        UpdateAutomationPolicyCommand(
          tenantId: tenantId,
          actorId: actorId,
          autoIssueEnabled: current.autoIssueEnabled,
          autoSendEnabled: current.autoSendEnabled,
          expectedPolicyVersion: current.policy.policyVersion,
        ),
      );
      if (isClosed) {
        return AutomationPolicySaveResult.failed;
      }
      emit(
        current.copyWith(
          isSubmitting: false,
          policy: policy,
          autoIssueEnabled: policy.autoIssueEnabled,
          autoSendEnabled: policy.autoSendEnabled,
        ),
      );
      return AutomationPolicySaveResult.saved;
    } on ConfigNotReadyException {
      _emitIdle(current);
      return AutomationPolicySaveResult.notReady;
    } on EInvoiceBlockedException catch (error) {
      _emitIdle(current);
      if (error.code == EInvoiceBlockedCodes.stateChanged) {
        return AutomationPolicySaveResult.stateChanged;
      }
      return AutomationPolicySaveResult.failed;
    } catch (_) {
      _emitIdle(current);
      return AutomationPolicySaveResult.failed;
    }
  }

  void _emitIdle(AutomationPolicyLoaded current) {
    if (isClosed) {
      return;
    }
    emit(current.copyWith(isSubmitting: false));
  }
}
