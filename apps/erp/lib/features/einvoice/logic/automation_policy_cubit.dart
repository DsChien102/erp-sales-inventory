import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/logic/automation_policy_state.dart';
import 'package:erp/features/einvoice/logic/configuration_query_failure.dart';

enum AutomationPolicySaveResult {
  saved,
  notReady,
  stateChanged,
  failed,
}

final class AutomationPolicyCubit extends Cubit<AutomationPolicyState> {
  AutomationPolicyCubit({
    required EInvoiceConfigurationRepository repository,
  })  : _repository = repository,
        super(const AutomationPolicyInitial());

  final EInvoiceConfigurationRepository _repository;

  Future<void> load() async {
    emit(const AutomationPolicyLoading());
    try {
      final policy = await _repository.getAutomationPolicy();
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
      final policy = await _repository.updateAutomationPolicy(
        expectedPolicyVersion: current.policy.policyVersion,
        autoIssueEnabled: current.autoIssueEnabled,
        autoSendEnabled: current.autoSendEnabled,
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
    } on AppException catch (e) {
      _emitIdle(current);
      if (e.code == EInvoiceErrorCodes.configNotReady) {
        return AutomationPolicySaveResult.notReady;
      }
      if (e.code == EInvoiceErrorCodes.stateChanged) {
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
