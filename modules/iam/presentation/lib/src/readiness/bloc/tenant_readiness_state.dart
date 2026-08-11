import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';

final class TenantReadinessState {
  const TenantReadinessState({
    this.status = IamLoadStatus.initial,
    this.readiness,
    this.isActivating = false,
    this.activation,
    this.failure,
    this.successMessage,
  });

  final IamLoadStatus status;
  final TenantReadinessDto? readiness;
  final bool isActivating;
  final TenantActivationResultDto? activation;
  final IamUiFailure? failure;
  final String? successMessage;

  bool get mandatorySetupComplete {
    final r = readiness;
    return r != null && r.status == TenantLifecycleStatus.provisioning && r.blockers.isEmpty;
  }

  bool get canActivate => readiness?.canActivate ?? false;

  bool get canStartActivation => canActivate || mandatorySetupComplete;

  TenantReadinessState copyWith({
    IamLoadStatus? status,
    TenantReadinessDto? readiness,
    bool? isActivating,
    TenantActivationResultDto? activation,
    IamUiFailure? failure,
    String? successMessage,
    bool clearReadiness = false,
    bool clearActivation = false,
    bool clearFailure = false,
    bool clearSuccessMessage = false,
  }) {
    return TenantReadinessState(
      status: status ?? this.status,
      readiness: clearReadiness ? null : (readiness ?? this.readiness),
      isActivating: isActivating ?? this.isActivating,
      activation: clearActivation ? null : (activation ?? this.activation),
      failure: clearFailure ? null : (failure ?? this.failure),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}
