import 'package:equatable/equatable.dart';

final class SalesOrderCancellationId extends Equatable {
  const SalesOrderCancellationId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
