import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../ports/i_partner_command_gateway.dart';
import 'update_partner_profile_command.dart';
import 'update_partner_profile_result.dart';

final class UpdatePartnerProfileCommandHandler
    implements ICommandHandler<UpdatePartnerProfileCommand, UpdatePartnerProfileResult> {
  UpdatePartnerProfileCommandHandler({
    required IPartnerCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IPartnerCommandGateway _commandGateway;

  @override
  Future<UpdatePartnerProfileResult> handle(
    UpdatePartnerProfileCommand command,
  ) async {
    final transientPartner = BusinessPartner.rehydrate(
      id: BusinessPartnerId(command.partnerId),
      tenantId: TenantId(command.tenantId),
      entityType: command.entityType,
      displayName: PartnerName(command.displayName),
      individualName: _optionalName(command.individualName),
      businessName: _optionalName(command.businessName),
      companyName: _optionalName(command.companyName),
      phone: PhoneNumber(command.phone),
      roles: command.roles,
      status: command.currentStatus,
      createdBy: command.actorId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedBy: command.actorId,
      updatedAt: DateTime.now(),
      version: command.expectedVersion,
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

    final updated = transientPartner.updateProfile(
      entityType: command.entityType,
      displayName: PartnerName(command.displayName),
      individualName: _optionalName(command.individualName),
      businessName: _optionalName(command.businessName),
      companyName: _optionalName(command.companyName),
      phone: PhoneNumber(command.phone),
      roles: command.roles,
      actorId: command.actorId,
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

    final newVersion = await _commandGateway.update(
      partner: updated,
      roles: command.roles,
      confirmDuplicate: command.confirmDuplicate,
      expectedVersion: command.expectedVersion,
      actorId: command.actorId,
    );

    return UpdatePartnerProfileResult(
      businessPartnerId: command.partnerId,
      version: newVersion,
      hasTaxCodeWarning: updated.hasTaxCodeWarning,
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
