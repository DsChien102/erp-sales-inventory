import 'package:equatable/equatable.dart';
import 'package:vet45_einvoice_application/application.dart';

import '../support/configuration_query_failure.dart';

sealed class AutomationPolicyState extends Equatable {
  const AutomationPolicyState();

  @override
  List<Object?> get props => [];
}

final class AutomationPolicyInitial extends AutomationPolicyState {
  const AutomationPolicyInitial();
}

final class AutomationPolicyLoading extends AutomationPolicyState {
  const AutomationPolicyLoading();
}

final class AutomationPolicyLoaded extends AutomationPolicyState {
  const AutomationPolicyLoaded({
    required this.policy,
    required this.autoIssueEnabled,
    required this.autoSendEnabled,
    this.isSubmitting = false,
  });

  final AutomationPolicyDto policy;
  final bool autoIssueEnabled;
  final bool autoSendEnabled;
  final bool isSubmitting;

  AutomationPolicyLoaded copyWith({
    AutomationPolicyDto? policy,
    bool? autoIssueEnabled,
    bool? autoSendEnabled,
    bool? isSubmitting,
  }) {
    return AutomationPolicyLoaded(
      policy: policy ?? this.policy,
      autoIssueEnabled: autoIssueEnabled ?? this.autoIssueEnabled,
      autoSendEnabled: autoSendEnabled ?? this.autoSendEnabled,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
    policy.policyVersion,
    policy.autoIssueEnabled,
    policy.autoSendEnabled,
    autoIssueEnabled,
    autoSendEnabled,
    isSubmitting,
  ];
}

final class AutomationPolicyError extends AutomationPolicyState {
  const AutomationPolicyError(this.failure);

  final ConfigurationQueryFailure failure;

  @override
  List<Object?> get props => [failure];
}
