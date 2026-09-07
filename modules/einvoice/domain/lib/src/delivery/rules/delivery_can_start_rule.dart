import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/delivery_kind.dart';

/// Guards start of a business InvoiceDelivery.
final class DeliveryCanStartRule implements IBusinessRule {
  const DeliveryCanStartRule({
    required this.kind,
    required this.hasPriorDeliveryHistory,
    required this.hasPriorInitialDelivery,
    required this.invoiceHasActiveLock,
  });

  final DeliveryKind kind;
  final bool hasPriorDeliveryHistory;
  final bool hasPriorInitialDelivery;
  final bool invoiceHasActiveLock;

  @override
  bool isBroken() {
    if (invoiceHasActiveLock) {
      return true;
    }
    return switch (kind) {
      DeliveryKind.initial => hasPriorInitialDelivery,
      DeliveryKind.resend => !hasPriorDeliveryHistory,
    };
  }

  @override
  String get message {
    if (invoiceHasActiveLock) {
      return 'Cannot start delivery while another delivery is active or unknown';
    }
    return switch (kind) {
      DeliveryKind.initial => 'Initial delivery already exists for this electronic invoice',
      DeliveryKind.resend => 'Resend requires prior delivery history for this electronic invoice',
    };
  }
}
