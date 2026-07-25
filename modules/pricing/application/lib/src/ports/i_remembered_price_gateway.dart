import 'package:vet45_pricing_domain/domain.dart';

import '../customer_price_rule/commands/save_remembered_price_from_order/remembered_price_outcome_dto.dart';

abstract interface class IRememberedPriceGateway {
  Future<RememberedPriceOutcomeDto> save(RememberedPriceRequest request);
}
