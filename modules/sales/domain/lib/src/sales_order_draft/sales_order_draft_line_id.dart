import 'package:equatable/equatable.dart';

final class SalesOrderDraftLineId extends Equatable {
  const SalesOrderDraftLineId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
