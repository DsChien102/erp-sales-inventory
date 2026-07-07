import 'dart:async';

import 'package:async_query/async_query.dart';
import 'package:flutter/widgets.dart';

import 'infinite_query_result.dart';
import 'query_client_provider.dart';

typedef UseInfiniteQueryBuilder<TData, TPageParam> = Widget Function(
  BuildContext context,
  InfiniteQueryResult<TData, TPageParam> result,
);

/// Declarative widget for paginated/infinite queries.
class UseInfiniteQuery<TData, TPageParam> extends StatefulWidget {
  const UseInfiniteQuery({
    required this.queryKey,
    required this.queryFn,
    required this.initialPageParam,
    required this.getNextPageParam,
    required this.builder,
    this.client,
    this.getPreviousPageParam,
    this.staleTime,
    this.gcTime,
    this.retry,
    this.enabled = true,
    this.maxPages,
    super.key,
  });

  final QueryKey queryKey;
  final InfiniteQueryFn<TData, TPageParam> queryFn;
  final TPageParam initialPageParam;
  final GetNextPageParam<TData, TPageParam> getNextPageParam;
  final GetPreviousPageParam<TData, TPageParam>? getPreviousPageParam;
  final UseInfiniteQueryBuilder<TData, TPageParam> builder;
  final QueryClient? client;
  final Duration? staleTime;
  final Duration? gcTime;
  final int? retry;
  final bool enabled;
  final int? maxPages;

  @override
  State<UseInfiniteQuery<TData, TPageParam>> createState() =>
      _UseInfiniteQueryState<TData, TPageParam>();
}

class _UseInfiniteQueryState<TData, TPageParam>
    extends State<UseInfiniteQuery<TData, TPageParam>> {
  InfiniteQueryObserver<TData, TPageParam>? _observer;
  StreamSubscription<InfiniteQueryState<TData, TPageParam>>? _subscription;
  InfiniteQueryState<TData, TPageParam> _state =
      InfiniteQueryState<TData, TPageParam>();
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
  void didUpdateWidget(covariant UseInfiniteQuery<TData, TPageParam> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    final client = widget.client ?? QueryClientProvider.of(context);
    _observer = client.watchInfiniteQuery<TData, TPageParam>(
      queryKey: widget.queryKey,
      queryFn: widget.queryFn,
      initialPageParam: widget.initialPageParam,
      getNextPageParam: widget.getNextPageParam,
      getPreviousPageParam: widget.getPreviousPageParam,
      staleTime: widget.staleTime,
      gcTime: widget.gcTime,
      retry: widget.retry,
      enabled: widget.enabled,
      maxPages: widget.maxPages,
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
    final result = InfiniteQueryResult<TData, TPageParam>(
      _state,
      fetchNextPage: () =>
          _observer?.fetchNextPage() ?? Future.value(_state),
      refetch: () => _observer?.refetch() ?? Future.value(_state),
    );
    return widget.builder(context, result);
  }
}
