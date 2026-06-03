import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'i_query.dart';

abstract class QueryBase<TResult> implements IQuery<TResult> {
  final String id;

  @protected
  QueryBase([String? id]) : id = id ?? const Uuid().v7();
}
