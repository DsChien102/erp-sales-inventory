import 'package:admin/features/iam/presentation.dart';

enum PlatformTenantDetailStatus {
  initial,
  loading,
  success,
  failure,
  unauthorized,
}

final class PlatformTenantDetailState {
  const PlatformTenantDetailState({
    this.status = PlatformTenantDetailStatus.initial,
    this.organization,
    this.errorMessage,
    this.actionInProgress = false,
  });

  final PlatformTenantDetailStatus status;
  final OrganizationUiModel? organization;
  final String? errorMessage;
  final bool actionInProgress;

  PlatformTenantDetailState copyWith({
    PlatformTenantDetailStatus? status,
    OrganizationUiModel? organization,
    String? errorMessage,
    bool? actionInProgress,
    bool clearError = false,
  }) {
    return PlatformTenantDetailState(
      status: status ?? this.status,
      organization: organization ?? this.organization,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionInProgress: actionInProgress ?? this.actionInProgress,
    );
  }
}
