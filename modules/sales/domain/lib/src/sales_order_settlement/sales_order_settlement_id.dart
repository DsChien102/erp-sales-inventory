import 'package:equatable/equatable.dart';

final class SalesOrderSettlementId extends Equatable {
  const SalesOrderSettlementId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
