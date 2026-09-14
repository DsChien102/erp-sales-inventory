import 'package:equatable/equatable.dart';

final class SalesReceiptActivityId extends Equatable {
  const SalesReceiptActivityId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
