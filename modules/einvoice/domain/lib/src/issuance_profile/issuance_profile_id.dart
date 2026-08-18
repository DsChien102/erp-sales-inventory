import 'package:equatable/equatable.dart';

/// Strongly-typed issuance profile identifier.
final class IssuanceProfileId extends Equatable {
  const IssuanceProfileId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
