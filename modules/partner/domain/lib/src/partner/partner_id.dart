import 'package:equatable/equatable.dart';

/// Strongly-typed partner identifier.
final class PartnerId extends Equatable {
  const PartnerId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
