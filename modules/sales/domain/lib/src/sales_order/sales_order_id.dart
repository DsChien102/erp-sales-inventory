import 'package:equatable/equatable.dart';

final class SalesOrderId extends Equatable {
  const SalesOrderId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
