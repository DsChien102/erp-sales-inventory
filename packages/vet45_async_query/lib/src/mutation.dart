import 'dart:async';

import 'mutation_context.dart';
import 'mutation_options.dart';
import 'mutation_state.dart';
import 'notify_scheduler.dart';
import 'retry_resolver.dart';

typedef MutationListener<TData, TVariables> = void Function(
  MutationState<TData, TVariables> state,
);

/// Executes a single mutation with optimistic updates and rollback.
class Mutation<TData, TVariables> {
  Mutation({
    required this.options,
    required this.context,
    required NotifyScheduler scheduler,
  })  : _scheduler = scheduler,
        _retryResolver = RetryResolver(
          maxRetries: options.retry ?? 0,
          retryDelay:
              options.retryDelay ?? MutationOptionsDefaults().retryDelay,
          retryOn: (_) => true,
        );

  final MutationOptions<TData, TVariables> options;
  final MutationContext context;
  final NotifyScheduler _scheduler;
  final RetryResolver _retryResolver;

  final _listeners = <MutationListener<TData, TVariables>>{};
  MutationState<TData, TVariables> _state = MutationState<TData, TVariables>();

  MutationState<TData, TVariables> get state => _state;

  void addListener(MutationListener<TData, TVariables> listener) {
    _listeners.add(listener);
    listener(_state);
  }

  void removeListener(MutationListener<TData, TVariables> listener) {
    _listeners.remove(listener);
  }

  Future<MutationState<TData, TVariables>> mutate(TVariables variables) async {
    _setState(
      _state.copyWith(
        status: MutationStatus.pending,
        variables: variables,
        submittedAt: DateTime.now(),
        clearError: true,
      ),
    );

    Object? rollbackContext;
    try {
      rollbackContext = await options.onMutate?.call(variables);
    } catch (error) {
      await _handleError(error, variables, rollbackContext);
      return _state;
    }

    var attempt = 0;
    while (true) {
      try {
        final data = await options.mutationFn(variables);
        await _handleSuccess(data, variables);
        return _state;
      } catch (error) {
        attempt++;
        if (!_retryResolver.shouldRetry(error, attempt)) {
          await _handleError(error, variables, rollbackContext);
          return _state;
        }
        final delay = _retryResolver.delayForAttempt(attempt);
        await Future<void>.delayed(delay);
      }
    }
  }

  Future<void> _handleSuccess(TData data, TVariables variables) async {
    _setState(
      _state.copyWith(
        status: MutationStatus.success,
        data: data,
        settledAt: DateTime.now(),
      ),
    );
    await options.onSuccess?.call(data, variables, context);
    await options.onSettled?.call(data, null, variables, context);
  }

  Future<void> _handleError(
    Object error,
    TVariables variables,
    Object? rollbackContext,
  ) async {
    _setState(
      _state.copyWith(
        status: MutationStatus.error,
        error: error,
        failureCount: _state.failureCount + 1,
        settledAt: DateTime.now(),
      ),
    );
    await options.onError?.call(error, variables, rollbackContext, context);
    await options.onSettled?.call(null, error, variables, context);
  }

  void reset() {
    _setState(MutationState<TData, TVariables>());
  }

  void _setState(MutationState<TData, TVariables> state) {
    _state = state;
    _scheduler.schedule(() {
      for (final listener in _listeners.toList()) {
        listener(_state);
      }
    });
  }

  void dispose() {
    _listeners.clear();
  }
}
