import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../entities/sales_order_draft_line.dart';

final class DraftMustContainValidLineRule implements IBusinessRule {
  const DraftMustContainValidLineRule(this.lines);

  final List<SalesOrderDraftLine> lines;

  @override
  bool isBroken() => lines.isEmpty || lines.any((line) => line.quantity.isZero);

  @override
  String get message => 'Persisted draft must contain at least one line with positive quantity.';
}
