import 'package:equatable/equatable.dart';

/// Strongly-typed membership identifier.
final class TenantMembershipId extends Equatable {
  const TenantMembershipId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
