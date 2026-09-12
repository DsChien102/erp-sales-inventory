import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_receipt_activity_type.dart';
import '../sales_receipt_activity_id.dart';

final class SalesReceiptActivity extends Entity<SalesReceiptActivityId> {
  SalesReceiptActivity({
    required super.id,
    required this.type,
    required this.occurredAt,
    this.channel,
  });

  final SalesReceiptActivityType type;
  final DateTime occurredAt;
  final String? channel;
}
