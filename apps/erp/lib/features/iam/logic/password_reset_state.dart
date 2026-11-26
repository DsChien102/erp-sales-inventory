import '../data/models/password_reset_result.dart';
import 'iam_ui_failure.dart';

enum PasswordResetStep { initial, verifyCode, createNewPassword }

final class PasswordResetState {
  const PasswordResetState({
    this.step = PasswordResetStep.initial,
    this.request,
    this.isSubmitting = false,
    this.verified = false,
    this.completion,
    this.failure,
    this.codeError,
    required this.nowUtc,
  });

  final PasswordResetStep step;
  final PasswordResetRequestResult? request;
  final bool isSubmitting;
  final bool verified;
  final PasswordResetCompletionResult? completion;
  final IamUiFailure? failure;
  final String? codeError;
  final DateTime nowUtc;

  String? get operationId => request?.operationId;

  String get maskedEmail => request?.maskedEmail ?? '';

  int get resendSecondsRemaining {
    final availableAt = request?.resendAvailableAt;
    if (availableAt == null) return 0;
    final seconds = availableAt.difference(nowUtc).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  bool get canResend =>
      request != null && resendSecondsRemaining <= 0 && !isSubmitting;

  PasswordResetState copyWith({
    PasswordResetStep? step,
    PasswordResetRequestResult? request,
    bool? isSubmitting,
    bool? verified,
    PasswordResetCompletionResult? completion,
    IamUiFailure? failure,
    String? codeError,
    DateTime? nowUtc,
    bool clearFailure = false,
    bool clearCodeError = false,
    bool clearRequest = false,
    bool clearCompletion = false,
  }) {
    return PasswordResetState(
      step: step ?? this.step,
      request: clearRequest ? null : (request ?? this.request),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      verified: verified ?? this.verified,
      completion: clearCompletion ? null : (completion ?? this.completion),
      failure: clearFailure ? null : (failure ?? this.failure),
      codeError: clearCodeError ? null : (codeError ?? this.codeError),
      nowUtc: nowUtc ?? this.nowUtc,
    );
  }
}
