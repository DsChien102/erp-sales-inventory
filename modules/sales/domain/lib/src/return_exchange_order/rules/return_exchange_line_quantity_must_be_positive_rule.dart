import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../entities/return_exchange_line.dart';

final class ReturnExchangeLineQuantityMustBePositiveRule implements IBusinessRule {
  const ReturnExchangeLineQuantityMustBePositiveRule(this.lines);

  final List<ReturnExchangeLine> lines;

  @override
  bool isBroken() => lines.any((line) => line.quantity.quantityMicros <= 0);

  @override
  String get message => 'Return/exchange line quantity must be positive.';
}
