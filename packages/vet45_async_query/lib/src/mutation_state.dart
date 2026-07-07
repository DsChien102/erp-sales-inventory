/// Mutation lifecycle status.
enum MutationStatus {
  idle,
  pending,
  success,
  error,
}

/// Immutable snapshot of a mutation's state.
class MutationState<TData, TVariables> {
  const MutationState({
    this.data,
    this.error,
    this.variables,
    this.status = MutationStatus.idle,
    this.failureCount = 0,
    this.submittedAt,
    this.settledAt,
  });

  final TData? data;
  final Object? error;
  final TVariables? variables;
  final MutationStatus status;
  final int failureCount;
  final DateTime? submittedAt;
  final DateTime? settledAt;

  bool get isIdle => status == MutationStatus.idle;
  bool get isPending => status == MutationStatus.pending;
  bool get isSuccess => status == MutationStatus.success;
  bool get isError => status == MutationStatus.error;

  MutationState<TData, TVariables> copyWith({
    TData? data,
    Object? error,
    TVariables? variables,
    MutationStatus? status,
    int? failureCount,
    DateTime? submittedAt,
    DateTime? settledAt,
    bool clearData = false,
    bool clearError = false,
    bool clearVariables = false,
  }) {
    return MutationState<TData, TVariables>(
      data: clearData ? null : (data ?? this.data),
      error: clearError ? null : (error ?? this.error),
      variables: clearVariables ? null : (variables ?? this.variables),
      status: status ?? this.status,
      failureCount: failureCount ?? this.failureCount,
      submittedAt: submittedAt ?? this.submittedAt,
      settledAt: settledAt ?? this.settledAt,
    );
  }
}
