import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CustomerPriceRuleUpdatedDomainEvent extends DomainEventBase {
  CustomerPriceRuleUpdatedDomainEvent({
    required this.ruleId,
    required this.previousVersion,
    required this.newVersion,
  });

  final String ruleId;
  final int previousVersion;
  final int newVersion;
}
