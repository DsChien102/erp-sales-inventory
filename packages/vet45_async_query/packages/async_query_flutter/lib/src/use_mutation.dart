import 'dart:async';

import 'package:async_query/async_query.dart';
import 'package:flutter/widgets.dart';

import 'mutation_result.dart';
import 'query_client_provider.dart';

typedef UseMutationBuilder<TData, TVariables> = Widget Function(
  BuildContext context,
  MutationResult<TData, TVariables> result,
);

/// Declarative widget that manages a mutation lifecycle.
class UseMutation<TData, TVariables> extends StatefulWidget {
  const UseMutation({
    required this.mutationFn,
    required this.builder,
    this.client,
    this.onMutate,
    this.onSuccess,
    this.onError,
    this.onSettled,
    this.retry,
    this.retryDelay,
    this.mutationKey,
    super.key,
  });

  final MutationFn<TData, TVariables> mutationFn;
  final UseMutationBuilder<TData, TVariables> builder;
  final QueryClient? client;
  final OnMutate<TData, TVariables>? onMutate;
  final OnMutationSuccess<TData, TVariables>? onSuccess;
  final OnMutationError<TData, TVariables>? onError;
  final OnMutationSettled<TData, TVariables>? onSettled;
  final int? retry;
  final Duration Function(int attempt)? retryDelay;
  final List<Object?>? mutationKey;

  @override
  State<UseMutation<TData, TVariables>> createState() =>
      _UseMutationState<TData, TVariables>();
}

class _UseMutationState<TData, TVariables>
    extends State<UseMutation<TData, TVariables>> {
  Mutation<TData, TVariables>? _mutation;
  MutationState<TData, TVariables> _state =
      MutationState<TData, TVariables>();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _buildMutation();
      _initialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant UseMutation<TData, TVariables> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mutationFn != widget.mutationFn) {
      _mutation?.removeListener(_onStateChanged);
      _buildMutation();
    }
  }

  void _buildMutation() {
    final client = widget.client ?? QueryClientProvider.of(context);
    _mutation = client.buildMutation<TData, TVariables>(
      mutationFn: widget.mutationFn,
      onMutate: widget.onMutate,
      onSuccess: widget.onSuccess,
      onError: widget.onError,
      onSettled: widget.onSettled,
      retry: widget.retry,
      retryDelay: widget.retryDelay,
      mutationKey: widget.mutationKey,
    )..addListener(_onStateChanged);
    _state = _mutation!.state;
  }

  void _onStateChanged(MutationState<TData, TVariables> state) {
    if (mounted) {
      setState(() => _state = state);
    }
  }

  @override
  void dispose() {
    _mutation?.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = _mutation;
    final result = MutationResult<TData, TVariables>(
      _state,
      mutate: (variables) =>
          mutation?.mutate(variables) ??
          Future.value(MutationState<TData, TVariables>()),
      reset: () => mutation?.reset(),
    );
    return widget.builder(context, result);
  }
}
