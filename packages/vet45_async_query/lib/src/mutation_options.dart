import 'mutation_context.dart';

/// Default options applied to all mutations unless overridden.
class MutationOptionsDefaults {
  const MutationOptionsDefaults({
    this.retry = 0,
    this.retryDelay = _defaultRetryDelay,
  });

  final int retry;
  final Duration Function(int attempt) retryDelay;

  static Duration _defaultRetryDelay(int attempt) {
    return Duration(milliseconds: 200 * (1 << attempt.clamp(0, 10)));
  }
}

typedef MutationFn<TData, TVariables> = Future<TData> Function(TVariables);

typedef OnMutate<TData, TVariables> = Future<Object?> Function(
  TVariables variables,
);

typedef OnMutationSuccess<TData, TVariables> = Future<void> Function(
  TData data,
  TVariables variables,
  MutationContext context,
);

typedef OnMutationError<TData, TVariables> = Future<void> Function(
  Object error,
  TVariables variables,
  Object? rollbackContext,
  MutationContext context,
);

typedef OnMutationSettled<TData, TVariables> = Future<void> Function(
  TData? data,
  Object? error,
  TVariables? variables,
  MutationContext context,
);

/// Per-mutation configuration.
class MutationOptions<TData, TVariables> {
  MutationOptions({
    required this.mutationFn,
    this.onMutate,
    this.onSuccess,
    this.onError,
    this.onSettled,
    this.retry,
    this.retryDelay,
    this.mutationKey,
  });

  final MutationFn<TData, TVariables> mutationFn;
  final OnMutate<TData, TVariables>? onMutate;
  final OnMutationSuccess<TData, TVariables>? onSuccess;
  final OnMutationError<TData, TVariables>? onError;
  final OnMutationSettled<TData, TVariables>? onSettled;
  final int? retry;
  final Duration Function(int attempt)? retryDelay;
  final List<Object?>? mutationKey;

  MutationOptions<TData, TVariables> mergeDefaults(
    MutationOptionsDefaults defaults,
  ) {
    return MutationOptions<TData, TVariables>(
      mutationFn: mutationFn,
      onMutate: onMutate,
      onSuccess: onSuccess,
      onError: onError,
      onSettled: onSettled,
      retry: retry ?? defaults.retry,
      retryDelay: retryDelay ?? defaults.retryDelay,
      mutationKey: mutationKey,
    );
  }
}
