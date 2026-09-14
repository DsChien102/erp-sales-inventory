import 'package:equatable/equatable.dart';

final class SalesOrderLineId extends Equatable {
  const SalesOrderLineId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
