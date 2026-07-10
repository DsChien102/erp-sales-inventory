import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../value_objects/email_address.dart';

/// Invoice billing profile fields.
final class InvoiceProfile extends ValueObject {
  const InvoiceProfile({
    this.invoiceName,
    this.invoiceAddress,
    this.invoiceEmail,
  });

  final String? invoiceName;
  final String? invoiceAddress;
  final EmailAddress? invoiceEmail;

  @override
  List<Object?> get props => [invoiceName, invoiceAddress, invoiceEmail];
}
