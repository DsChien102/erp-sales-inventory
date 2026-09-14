import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/return_exchange_line_kind.dart';
import '../../shared/value_objects/product_ref_snapshot.dart';
import '../../shared/value_objects/product_unit_ref_snapshot.dart';
import '../return_exchange_line_id.dart';

final class ReturnExchangeLine extends Entity<ReturnExchangeLineId> {
  ReturnExchangeLine({
    required super.id,
    required this.kind,
    required this.quantity,
    required this.lineTotal,
    this.sourceOrderLineId,
    this.sourceExchangeLineId,
    this.product,
    this.unit,
    this.conditionNote,
  });

  final ReturnExchangeLineKind kind;
  final Quantity quantity;
  final Money lineTotal;

  /// A returned line references exactly one source (XOR):
  /// [sourceOrderLineId] for an original sales order line, or
  /// [sourceExchangeLineId] for a previously exchanged-in line.
  final String? sourceOrderLineId;
  final String? sourceExchangeLineId;
  final ProductRefSnapshot? product;
  final ProductUnitRefSnapshot? unit;
  final String? conditionNote;
}
