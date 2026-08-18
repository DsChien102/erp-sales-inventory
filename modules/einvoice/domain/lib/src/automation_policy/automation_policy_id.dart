import 'package:equatable/equatable.dart';

/// Strongly-typed automation policy identifier.
final class AutomationPolicyId extends Equatable {
  const AutomationPolicyId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
