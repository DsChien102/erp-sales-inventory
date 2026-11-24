import 'partner_enums.dart';
import 'person_title.dart';

/// Delivery address fields shared by person and organization profiles.
final class DeliveryAddressInput {
  const DeliveryAddressInput({
    this.province,
    this.commune,
    this.address,
  });

  final String? province;
  final String? commune;
  final String? address;

  /// Dạng lồng `{province, commune, address}` mà `partner._insert_*_profile` đọc.
  Map<String, dynamic> toNestedJson() => <String, dynamic>{
    'province': province,
    'commune': commune,
    'address': address,
  };
}

/// Invoice fields shared by person and organization profiles.
final class InvoiceProfileInput {
  const InvoiceProfileInput({
    this.invoiceName,
    this.invoiceAddress,
    this.invoiceEmail,
  });

  final String? invoiceName;
  final String? invoiceAddress;
  final String? invoiceEmail;

  /// Dạng lồng `{name, address, email}` mà `partner._insert_*_profile` đọc.
  Map<String, dynamic> toNestedJson() => <String, dynamic>{
    'name': invoiceName,
    'address': invoiceAddress,
    'email': invoiceEmail,
  };
}

/// Person profile payload for create/update/contact flows.
final class PersonProfileInput {
  const PersonProfileInput({
    this.title,
    required this.fullName,
    this.nickname,
    required this.phone,
    this.phone2,
    this.email,
    this.taxCode,
    this.invoice,
    this.delivery,
    this.note,
  });

  /// Optional honorific — [PersonTitle] wrapping free-form user text.
  final PersonTitle? title;
  final String fullName;
  final String? nickname;
  final String phone;
  final String? phone2;
  final String? email;
  final String? taxCode;
  final InvoiceProfileInput? invoice;
  final DeliveryAddressInput? delivery;
  final String? note;

  /// Khoá gửi lên RPC. Gửi cả dạng lồng (SQL hiện tại) và dạng phẳng (SQL cũ): không bớt khoá nào.
  Map<String, dynamic> toRpcJson() => <String, dynamic>{
    'title': title?.value,
    'full_name': fullName,
    'nickname': nickname,
    'phone': phone,
    'phone2': phone2,
    'email': email,
    'tax_code': taxCode,
    'invoice': invoice?.toNestedJson(),
    'invoice_name': invoice?.invoiceName,
    'invoice_address': invoice?.invoiceAddress,
    'invoice_email': invoice?.invoiceEmail,
    'delivery': delivery?.toNestedJson(),
    'delivery_province': delivery?.province,
    'delivery_commune': delivery?.commune,
    'delivery_address': delivery?.address,
    'note': note,
  };
}

/// Organization profile payload for create/update/transform flows.
final class OrganizationProfileInput {
  const OrganizationProfileInput({
    required this.organizationType,
    required this.organizationName,
    this.shortName,
    this.intlName,
    required this.phone,
    this.email,
    this.taxCode,
    this.companyAddress,
    this.invoice,
    this.delivery,
    this.note,
  });

  final OrganizationType organizationType;
  final String organizationName;
  final String? shortName;
  final String? intlName;
  final String phone;
  final String? email;
  final String? taxCode;
  final String? companyAddress;
  final InvoiceProfileInput? invoice;
  final DeliveryAddressInput? delivery;
  final String? note;

  /// Khoá gửi lên RPC (xem [PersonProfileInput.toRpcJson]).
  Map<String, dynamic> toRpcJson() => <String, dynamic>{
    'organization_type': switch (organizationType) {
      OrganizationType.company => 'company',
      OrganizationType.businessHousehold => 'business_household',
      OrganizationType.other => 'other',
    },
    'organization_name': organizationName,
    'short_name': shortName,
    'intl_name': intlName,
    'phone': phone,
    'email': email,
    'tax_code': taxCode,
    'company_address': companyAddress,
    'invoice': invoice?.toNestedJson(),
    'invoice_name': invoice?.invoiceName,
    'invoice_address': invoice?.invoiceAddress,
    'invoice_email': invoice?.invoiceEmail,
    'delivery': delivery?.toNestedJson(),
    'delivery_province': delivery?.province,
    'delivery_commune': delivery?.commune,
    'delivery_address': delivery?.address,
    'note': note,
  };
}
