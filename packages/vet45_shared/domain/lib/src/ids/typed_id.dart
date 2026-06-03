import 'package:equatable/equatable.dart';

/// Strongly typed identifier wrapper for domain entities and value objects.
final class TypedId<T> extends Equatable {
  const TypedId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
