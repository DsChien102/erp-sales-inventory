import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../remembered_price_request_status.dart';

final class RememberedPriceRequestMustBeOpenRule implements IBusinessRule {
  const RememberedPriceRequestMustBeOpenRule(this.status);

  final RememberedPriceRequestStatus status;

  @override
  bool isBroken() => status != RememberedPriceRequestStatus.received;

  @override
  String get message => 'Remembered price request is already terminal.';
}
