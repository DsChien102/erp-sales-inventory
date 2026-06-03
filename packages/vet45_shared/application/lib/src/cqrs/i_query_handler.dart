import 'i_query.dart';

abstract interface class IQueryHandler<TQuery extends IQuery<TResult>, TResult> {
  Future<TResult> handle(TQuery query);
}
