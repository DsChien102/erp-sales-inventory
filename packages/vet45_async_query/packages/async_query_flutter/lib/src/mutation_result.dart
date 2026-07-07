import 'package:async_query/async_query.dart';

/// View model exposing mutation state shortcuts for widget builders.
class MutationResult<TData, TVariables> {
  const MutationResult(this.state, {required this.mutate, required this.reset});

  final MutationState<TData, TVariables> state;
  final Future<MutationState<TData, TVariables>> Function(TVariables) mutate;
  final void Function() reset;

  TData? get data => state.data;
  Object? get error => state.error;
  TVariables? get variables => state.variables;

  bool get isIdle => state.isIdle;
  bool get isPending => state.isPending;
  bool get isSuccess => state.isSuccess;
  bool get isError => state.isError;
}
