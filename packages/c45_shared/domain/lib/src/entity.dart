import 'package:meta/meta.dart';

import 'business_rule.dart';
import 'business_rule_validation_exception.dart';
import 'domain_event.dart';

abstract class Entity<Id> {
  final Id id;

  Entity({required this.id});

  List<IDomainEvent>? _domainEvents;

  Iterable<IDomainEvent>? get domainEvents =>
      _domainEvents != null ? List.unmodifiable(_domainEvents!) : null;

  @protected
  void addDomainEvent(IDomainEvent event) {
    _domainEvents ??= [];
    _domainEvents!.add(event);
  }

  void clearDomainEvent() {
    _domainEvents?.clear();
  }

  @protected
  void checkRule(IBusinessRule rule) {
    if (rule.isBroken()) {
      throw BusinessRuleValidationException(rule);
    }
  }
}
