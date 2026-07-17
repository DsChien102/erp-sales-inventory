import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CustomerPriceRuleReenabledDomainEvent extends DomainEventBase {
  CustomerPriceRuleReenabledDomainEvent({
    required this.ruleId,
    required this.previousVersion,
    required this.newVersion,
  });

  final String ruleId;
  final int previousVersion;
  final int newVersion;
}
