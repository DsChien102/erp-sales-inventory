import 'package:equatable/equatable.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import '../support/configuration_query_failure.dart';

sealed class EInvoiceConfigurationOverviewState extends Equatable {
  const EInvoiceConfigurationOverviewState();

  @override
  List<Object?> get props => [];
}

final class EInvoiceConfigurationOverviewInitial extends EInvoiceConfigurationOverviewState {
  const EInvoiceConfigurationOverviewInitial();
}

final class EInvoiceConfigurationOverviewLoading extends EInvoiceConfigurationOverviewState {
  const EInvoiceConfigurationOverviewLoading();
}

final class EInvoiceConfigurationOverviewLoaded extends EInvoiceConfigurationOverviewState {
  const EInvoiceConfigurationOverviewLoaded({
    required this.readiness,
    required this.connection,
    required this.profile,
    required this.templates,
    required this.policy,
  });

  final ConfigurationReadinessDto readiness;
  final ProviderConnectionSummaryDto connection;
  final IssuanceProfileDto profile;
  final List<ProviderTemplateDto> templates;
  final AutomationPolicyDto policy;

  bool get isReady =>
      readiness.level == ConfigurationReadinessLevel.ready ||
      readiness.level == ConfigurationReadinessLevel.readyWithWarnings;

  int get blockerCount => readiness.blockers.length;

  bool get connectionIncomplete => connection.status != ProviderConnectionStatus.connected;

  bool get issuanceIncomplete {
    final templateId = profile.templateId;
    return templateId == null || templateId.isEmpty;
  }

  @override
  List<Object?> get props => [
    readiness.level,
    readiness.blockers,
    readiness.warnings,
    connection,
    profile,
    templates,
    policy,
  ];
}

final class EInvoiceConfigurationOverviewError extends EInvoiceConfigurationOverviewState {
  const EInvoiceConfigurationOverviewError(this.failure);

  final ConfigurationQueryFailure failure;

  @override
  List<Object?> get props => [failure];
}
