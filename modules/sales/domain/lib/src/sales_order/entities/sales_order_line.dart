import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../shared/value_objects/product_ref_snapshot.dart';
import '../../shared/value_objects/product_unit_ref_snapshot.dart';
import '../sales_order_line_id.dart';

final class SalesOrderLine extends Entity<SalesOrderLineId> {
  SalesOrderLine({
    required super.id,
    required this.product,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.note,
  });

  final ProductRefSnapshot product;
  final ProductUnitRefSnapshot unit;
  final Quantity quantity;
  final Money unitPrice;
  final Money lineTotal;
  final String? note;
}
