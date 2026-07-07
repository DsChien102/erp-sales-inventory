import 'package:async_query/async_query.dart';

/// View model exposing query state shortcuts for widget builders.
class QueryResult<T> {
  const QueryResult(this.state, {required this.refetch});

  final QueryState<T> state;
  final Future<QueryState<T>> Function() refetch;

  T? get data => state.data;
  Object? get error => state.error;

  bool get isLoading => state.isLoading;
  bool get isFetching => state.isFetching;
  bool get isRefetching => state.isRefetching;
  bool get isError => state.isError;
  bool get isSuccess => state.isSuccess;
  bool get isStale => state.isStale;
  bool get hasData => state.hasData;
}
