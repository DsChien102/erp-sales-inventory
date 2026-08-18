import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Generic business rule for simple predicate checks.
final class PredicateBusinessRule implements IBusinessRule {
  const PredicateBusinessRule({
    required this.predicate,
    required this.ruleMessage,
  });

  final bool predicate;
  final String ruleMessage;

  @override
  bool isBroken() => predicate;

  @override
  String get message => ruleMessage;
}
