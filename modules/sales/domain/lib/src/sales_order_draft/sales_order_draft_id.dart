import 'package:equatable/equatable.dart';

final class SalesOrderDraftId extends Equatable {
  const SalesOrderDraftId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
