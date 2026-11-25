final class VerifyEmailState {
  const VerifyEmailState({
    required this.resendAvailableAt,
    required this.now,
    this.submitting = false,
    this.resending = false,
    this.verified = false,
    this.verifiedUserId,
    this.failure,
    this.resendFailure,
  });

  final bool submitting;

  /// Đang gửi lại mã (không khoá ô mã và nút Xác minh).
  final bool resending;
  final bool verified;
  final String? verifiedUserId;
  final String? failure;

  /// Lỗi gửi lại mã; tách khỏi [failure] (lỗi mã) để ô mã không đỏ.
  final String? resendFailure;
  final DateTime resendAvailableAt;
  final DateTime now;

  bool get canResend => !submitting && !resending && !now.isBefore(resendAvailableAt);

  Duration get remaining {
    if (canResend) return Duration.zero;
    final diff = resendAvailableAt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  VerifyEmailState copyWith({
    bool? submitting,
    bool? resending,
    bool? verified,
    String? verifiedUserId,
    String? failure,
    String? resendFailure,
    DateTime? resendAvailableAt,
    DateTime? now,
    bool clearFailure = false,
    bool clearResendFailure = false,
  }) {
    return VerifyEmailState(
      submitting: submitting ?? this.submitting,
      resending: resending ?? this.resending,
      verified: verified ?? this.verified,
      verifiedUserId: verifiedUserId ?? this.verifiedUserId,
      failure: clearFailure ? null : (failure ?? this.failure),
      resendFailure: clearResendFailure
          ? null
          : (resendFailure ?? this.resendFailure),
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      now: now ?? this.now,
    );
  }
}
