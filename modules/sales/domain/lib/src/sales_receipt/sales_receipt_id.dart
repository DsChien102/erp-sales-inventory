import 'package:equatable/equatable.dart';

final class SalesReceiptId extends Equatable {
  const SalesReceiptId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
