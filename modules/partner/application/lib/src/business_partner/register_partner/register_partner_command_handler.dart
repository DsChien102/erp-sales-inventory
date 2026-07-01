import 'package:uuid/uuid.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../ports/i_partner_command_gateway.dart';
import 'register_partner_command.dart';
import 'register_partner_result.dart';

final class RegisterPartnerCommandHandler
    implements ICommandHandler<RegisterPartnerCommand, RegisterPartnerResult> {
  RegisterPartnerCommandHandler({
    required IPartnerCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<RegisterPartnerResult> handle(RegisterPartnerCommand command) async {
    final partner = BusinessPartner.register(
      id: BusinessPartnerId(const Uuid().v4()),
      tenantId: TenantId(command.tenantId),
      entityType: command.entityType,
      displayName: PartnerName(command.displayName),
      phone: PhoneNumber(command.phone),
      roles: command.roles,
      actorId: command.actorId,
      individualName: _optionalName(command.individualName),
      businessName: _optionalName(command.businessName),
      companyName: _optionalName(command.companyName),
      email: _optionalEmail(command.email),
      taxCode: _optionalTaxCode(command.taxCode),
      address: _optionalAddress(command.address),
      invoiceProfile: _optionalInvoiceProfile(
        invoiceName: command.invoiceName,
        invoiceAddress: command.invoiceAddress,
        invoiceEmail: command.invoiceEmail,
      ),
      bankAccount: _optionalBankAccount(
        bankName: command.bankName,
        accountNumber: command.bankAccountNumber,
        accountHolder: command.bankAccountHolder,
      ),
      note: command.note,
    );

    final businessPartnerId = await _commandGateway.register(
      partner: partner,
      confirmDuplicate: command.confirmDuplicate,
      idempotencyKey: command.id,
    );

    return RegisterPartnerResult(
      businessPartnerId: businessPartnerId,
      hasTaxCodeWarning: partner.hasTaxCodeWarning,
    );
  }

  PartnerName? _optionalName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return PartnerName(trimmed);
  }

  EmailAddress? _optionalEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return EmailAddress(trimmed);
  }

  TaxCode? _optionalTaxCode(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return TaxCode(trimmed);
  }

  Address? _optionalAddress(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return Address(trimmed);
  }

  InvoiceProfile? _optionalInvoiceProfile({
    required String? invoiceName,
    required String? invoiceAddress,
    required String? invoiceEmail,
  }) {
    final profile = InvoiceProfile(
      invoiceName: _optionalName(invoiceName),
      invoiceAddress: invoiceAddress?.trim().isEmpty ?? true
          ? null
          : Address(invoiceAddress!.trim()),
      invoiceEmail: _optionalEmail(invoiceEmail),
    );
    return profile.isEmpty ? null : profile;
  }

  BankAccount? _optionalBankAccount({
    required String? bankName,
    required String? accountNumber,
    required String? accountHolder,
  }) {
    final resolvedBankName = bankName?.trim();
    final resolvedAccountNumber = accountNumber?.trim();
    final resolvedAccountHolder = accountHolder?.trim();
    if (resolvedBankName == null ||
        resolvedBankName.isEmpty ||
        resolvedAccountNumber == null ||
        resolvedAccountNumber.isEmpty ||
        resolvedAccountHolder == null ||
        resolvedAccountHolder.isEmpty) {
      return null;
    }
    return BankAccount(
      bankName: PartnerName(resolvedBankName),
      accountNumber: resolvedAccountNumber,
      accountHolder: PartnerName(resolvedAccountHolder),
    );
  }
}
