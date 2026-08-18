import 'package:equatable/equatable.dart';

/// Strongly-typed provider connection identifier.
final class ProviderConnectionId extends Equatable {
  const ProviderConnectionId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
