import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CustomerPriceRuleCreatedDomainEvent extends DomainEventBase {
  CustomerPriceRuleCreatedDomainEvent({required this.ruleId});

  final String ruleId;
}
