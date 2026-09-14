import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/return_exchange_line_kind.dart';
import '../entities/return_exchange_line.dart';

final class ReturnExchangeMustHaveReturnedItemRule implements IBusinessRule {
  const ReturnExchangeMustHaveReturnedItemRule(this.lines);

  final List<ReturnExchangeLine> lines;

  @override
  bool isBroken() => !lines.any((line) => line.kind == ReturnExchangeLineKind.returned);

  @override
  String get message => 'Return/exchange confirmation requires at least one returned item.';
}
