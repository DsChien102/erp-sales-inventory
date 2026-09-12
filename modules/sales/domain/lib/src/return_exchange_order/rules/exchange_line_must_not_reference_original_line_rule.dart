import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/return_exchange_line_kind.dart';
import '../entities/return_exchange_line.dart';

final class ExchangeLineMustNotReferenceOriginalLineRule implements IBusinessRule {
  const ExchangeLineMustNotReferenceOriginalLineRule(this.lines);

  final List<ReturnExchangeLine> lines;

  @override
  bool isBroken() => lines.any(
    (line) => line.kind == ReturnExchangeLineKind.exchange && line.sourceOrderLineId != null,
  );

  @override
  String get message => 'Exchange lines must use current product/unit references.';
}
