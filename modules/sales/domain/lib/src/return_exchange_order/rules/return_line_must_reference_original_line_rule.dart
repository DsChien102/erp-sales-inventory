import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/return_exchange_line_kind.dart';
import '../entities/return_exchange_line.dart';

final class ReturnLineMustReferenceOriginalLineRule implements IBusinessRule {
  const ReturnLineMustReferenceOriginalLineRule(this.lines);

  final List<ReturnExchangeLine> lines;

  @override
  bool isBroken() => lines.any((line) {
    if (line.kind != ReturnExchangeLineKind.returned) return false;
    final hasOriginal = line.sourceOrderLineId?.trim().isNotEmpty ?? false;
    final hasExchange = line.sourceExchangeLineId?.trim().isNotEmpty ?? false;
    // Broken unless exactly one source is present (neither or both is invalid).
    return hasOriginal == hasExchange;
  });

  @override
  String get message =>
      'Returned lines must reference exactly one source: an original sales order line or a source exchange line.';
}
