import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../remembered_price_result_type.dart';

final class RememberedPriceSavedDomainEvent extends DomainEventBase {
  RememberedPriceSavedDomainEvent({
    required this.requestId,
    required this.ruleId,
    required this.ruleVersion,
    required this.resultType,
  });

  final String requestId;
  final String ruleId;
  final int ruleVersion;
  final RememberedPriceResultType resultType;
}
