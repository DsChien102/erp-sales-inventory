import 'package:vet45_iam_application/application.dart';

enum PlatformUserDetailStatus {
  initial,
  loading,
  success,
  failure,
  notFound,
}

final class PlatformUserDetailState {
  const PlatformUserDetailState({
    this.status = PlatformUserDetailStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.isSubmitting = false,
  });

  final PlatformUserDetailStatus status;
  final PlatformUserDetailDto? user;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubmitting;

  PlatformUserDetailState copyWith({
    PlatformUserDetailStatus? status,
    PlatformUserDetailDto? user,
    String? errorMessage,
    String? successMessage,
    bool? isSubmitting,
    bool clearMessages = false,
  }) {
    return PlatformUserDetailState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
