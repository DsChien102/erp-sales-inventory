import 'package:equatable/equatable.dart';

final class ReturnExchangeLineId extends Equatable {
  const ReturnExchangeLineId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
