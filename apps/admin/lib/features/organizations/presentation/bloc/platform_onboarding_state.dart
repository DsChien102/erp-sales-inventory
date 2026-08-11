import 'package:vet45_iam_application/application.dart';

enum PlatformOnboardingLoadStatus {
  idle,
  searching,
  submitting,
  success,
  failure,
}

final class PlatformOnboardingState {
  const PlatformOnboardingState({
    this.status = PlatformOnboardingLoadStatus.idle,
    this.searchResults = const [],
    this.result,
    this.errorMessage,
  });

  final PlatformOnboardingLoadStatus status;
  final List<PlatformUserSummaryDto> searchResults;
  final TenantOnboardingResultDto? result;
  final String? errorMessage;

  PlatformOnboardingState copyWith({
    PlatformOnboardingLoadStatus? status,
    List<PlatformUserSummaryDto>? searchResults,
    TenantOnboardingResultDto? result,
    String? errorMessage,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return PlatformOnboardingState(
      status: status ?? this.status,
      searchResults: searchResults ?? this.searchResults,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
