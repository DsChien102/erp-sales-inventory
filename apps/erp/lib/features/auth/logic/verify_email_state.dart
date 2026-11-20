final class VerifyEmailState {
  const VerifyEmailState({
    required this.resendAvailableAt,
    required this.now,
    this.submitting = false,
    this.verified = false,
    this.verifiedUserId,
    this.failure,
  });

  final bool submitting;
  final bool verified;
  final String? verifiedUserId;
  final String? failure;
  final DateTime resendAvailableAt;
  final DateTime now;

  bool get canResend => !submitting && !now.isBefore(resendAvailableAt);

  Duration get remaining {
    if (canResend) return Duration.zero;
    final diff = resendAvailableAt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  VerifyEmailState copyWith({
    bool? submitting,
    bool? verified,
    String? verifiedUserId,
    String? failure,
    DateTime? resendAvailableAt,
    DateTime? now,
    bool clearFailure = false,
  }) {
    return VerifyEmailState(
      submitting: submitting ?? this.submitting,
      verified: verified ?? this.verified,
      verifiedUserId: verifiedUserId ?? this.verifiedUserId,
      failure: clearFailure ? null : (failure ?? this.failure),
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      now: now ?? this.now,
    );
  }
}
