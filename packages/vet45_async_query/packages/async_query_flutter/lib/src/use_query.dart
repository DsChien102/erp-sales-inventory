import 'dart:async';

import 'package:async_query/async_query.dart';
import 'package:flutter/widgets.dart';

import 'query_client_provider.dart';
import 'query_result.dart';

typedef UseQueryBuilder<T> = Widget Function(
  BuildContext context,
  QueryResult<T> result,
);

/// Declarative widget that subscribes to a cached query.
class UseQuery<T> extends StatefulWidget {
  const UseQuery({
    required this.queryKey,
    required this.queryFn,
    required this.builder,
    this.client,
    this.staleTime,
    this.gcTime,
    this.retry,
    this.retryDelay,
    this.retryOn,
    this.refetchOnMount,
    this.enabled = true,
    this.initialData,
    this.placeholderData,
    this.select,
    super.key,
  });

  final QueryKey queryKey;
  final QueryFn<T> queryFn;
  final UseQueryBuilder<T> builder;
  final QueryClient? client;
  final Duration? staleTime;
  final Duration? gcTime;
  final int? retry;
  final Duration Function(int attempt)? retryDelay;
  final bool Function(Object error)? retryOn;
  final bool? refetchOnMount;
  final bool enabled;
  final T? initialData;
  final T? placeholderData;
  final T Function(T data)? select;

  @override
  State<UseQuery<T>> createState() => _UseQueryState<T>();
}

class _UseQueryState<T> extends State<UseQuery<T>> {
  QueryObserver<T>? _observer;
  StreamSubscription<QueryState<T>>? _subscription;
  QueryState<T>? _state;
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      _subscribe();
      _subscribed = true;
    }
  }

  @override
  void didUpdateWidget(covariant UseQuery<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey ||
        oldWidget.enabled != widget.enabled) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    final client = widget.client ?? QueryClientProvider.of(context);
    _observer = client.watchQuery<T>(
      queryKey: widget.queryKey,
      queryFn: widget.queryFn,
      staleTime: widget.staleTime,
      gcTime: widget.gcTime,
      retry: widget.retry,
      retryDelay: widget.retryDelay,
      retryOn: widget.retryOn,
      refetchOnMount: widget.refetchOnMount,
      enabled: widget.enabled,
      initialData: widget.initialData,
      placeholderData: widget.placeholderData,
      select: widget.select,
    );
    _state = _observer!.currentState;
    _subscription = _observer!.stream.listen((state) {
      if (mounted) {
        setState(() => _state = state);
      }
    });
  }

  void _unsubscribe() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _observer?.dispose();
    _observer = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state ??
        QueryState<T>(status: QueryStatus.pending);
    final result = QueryResult<T>(
      state,
      refetch: () => _observer?.refetch() ?? Future.value(state),
    );
    return widget.builder(context, result);
  }
}
