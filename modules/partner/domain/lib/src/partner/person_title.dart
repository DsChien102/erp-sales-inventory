import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class PersonTitleMustNotBeBlankRule implements IBusinessRule {
  const PersonTitleMustNotBeBlankRule(this.value);

  final String value;

  @override
  bool isBroken() => value.trim().isEmpty;

  @override
  String get message => 'Person title must not be blank';
}

/// Optional honorific for person partners — wraps free-form user text (not enum-normalized).
final class PersonTitle extends ValueObject {
  PersonTitle(String raw) : value = raw {
    ValueObject.checkRule(PersonTitleMustNotBeBlankRule(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
