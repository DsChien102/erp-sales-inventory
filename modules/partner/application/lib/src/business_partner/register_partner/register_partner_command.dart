import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'register_partner_result.dart';

@RequiresPermission('partner.create')
@RequiresTenant()
final class RegisterPartnerCommand extends CommandBase<RegisterPartnerResult>
    implements ITenantScopedCommand {
  RegisterPartnerCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.entityType,
    required this.displayName,
    required this.phone,
    required this.roles,
    this.confirmDuplicate = false,
    this.individualName,
    this.businessName,
    this.companyName,
    this.email,
    this.taxCode,
    this.address,
    this.invoiceName,
    this.invoiceAddress,
    this.invoiceEmail,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.note,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final EntityType entityType;
  final String displayName;
  final String phone;
  final Set<PartnerRole> roles;
  final bool confirmDuplicate;
  final String? individualName;
  final String? businessName;
  final String? companyName;
  final String? email;
  final String? taxCode;
  final String? address;
  final String? invoiceName;
  final String? invoiceAddress;
  final String? invoiceEmail;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? note;
}
