import 'package:equatable/equatable.dart';

final class ReturnExchangeOrderId extends Equatable {
  const ReturnExchangeOrderId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
