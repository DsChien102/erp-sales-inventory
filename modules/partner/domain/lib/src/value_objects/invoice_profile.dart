import 'address.dart';
import 'email_address.dart';
import 'partner_name.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class InvoiceProfile extends ValueObject {
  const InvoiceProfile({
    this.invoiceName,
    this.invoiceAddress,
    this.invoiceEmail,
  });

  final PartnerName? invoiceName;
  final Address? invoiceAddress;
  final EmailAddress? invoiceEmail;

  bool get isEmpty =>
      invoiceName == null && invoiceAddress == null && invoiceEmail == null;

  @override
  List<Object?> get props => [invoiceName, invoiceAddress, invoiceEmail];
}
