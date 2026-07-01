import 'package:vet45_partner_domain/domain.dart';

final class PartnerDetailDto {
  const PartnerDetailDto({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.roles,
    required this.entityType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.createdBy,
    required this.updatedBy,
    this.email,
    this.address,
    this.taxCode,
    this.invoiceName,
    this.invoiceAddress,
    this.invoiceEmail,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.note,
    this.individualName,
    this.businessName,
    this.companyName,
  });

  final String id;
  final String displayName;
  final String phone;
  final String? email;
  final String? address;
  final String? taxCode;
  final String? invoiceName;
  final String? invoiceAddress;
  final String? invoiceEmail;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? note;
  final String? individualName;
  final String? businessName;
  final String? companyName;
  final Set<PartnerRole> roles;
  final EntityType entityType;
  final PartnerStatus status;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final int version;
}
