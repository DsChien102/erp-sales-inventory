import 'package:equatable/equatable.dart';

final class SalesPaymentTransactionId extends Equatable {
  const SalesPaymentTransactionId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
