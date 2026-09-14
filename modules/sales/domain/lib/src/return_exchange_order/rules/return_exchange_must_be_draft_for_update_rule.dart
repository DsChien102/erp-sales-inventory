import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/return_exchange_status.dart';

final class ReturnExchangeMustBeDraftForUpdateRule implements IBusinessRule {
  const ReturnExchangeMustBeDraftForUpdateRule(this.status);

  final ReturnExchangeStatus status;

  @override
  bool isBroken() => status != ReturnExchangeStatus.draft;

  @override
  String get message => 'Only technical draft return/exchange sessions can be updated.';
}
