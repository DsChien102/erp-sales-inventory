import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

/// Stub consumer — maps sales checkout events to history projection command.
/// Wire to inbox dispatcher when sales module events ship.
final class SalesOrderCheckedOutHistoryHandler {
  SalesOrderCheckedOutHistoryHandler({
    required IPartnerModule partnerModule,
  }) : _partnerModule = partnerModule;

  final IPartnerModule _partnerModule;

  Future<void> handle({
    required String tenantId,
    required String partnerId,
    required String sourceId,
    required String referenceCode,
    required DateTime transactionDate,
    required String status,
    double? amount,
    String? currency,
    bool canOpenSource = true,
  }) {
    return _partnerModule.executeCommandAsync(
      RecordPartnerHistoryCommand(
        tenantId: tenantId,
        partnerId: partnerId,
        role: PartnerRoleType.customer,
        transactionType: PartnerTransactionType.salesOrder,
        sourceModule: 'sales',
        sourceId: sourceId,
        referenceCode: referenceCode,
        transactionDate: transactionDate,
        status: status,
        amount: amount,
        currency: currency,
        canOpenSource: canOpenSource,
      ),
    );
  }
}

/// Stub consumer for `inventory.inbound.recorded`.
final class InventoryInboundRecordedHistoryHandler {
  InventoryInboundRecordedHistoryHandler({
    required IPartnerModule partnerModule,
  }) : _partnerModule = partnerModule;

  final IPartnerModule _partnerModule;

  Future<void> handle({
    required String tenantId,
    required String partnerId,
    required String sourceId,
    required String referenceCode,
    required DateTime transactionDate,
    required String status,
    double? amount,
    String? currency,
    bool canOpenSource = true,
  }) {
    return _partnerModule.executeCommandAsync(
      RecordPartnerHistoryCommand(
        tenantId: tenantId,
        partnerId: partnerId,
        role: PartnerRoleType.supplier,
        transactionType: PartnerTransactionType.inventoryInbound,
        sourceModule: 'inventory',
        sourceId: sourceId,
        referenceCode: referenceCode,
        transactionDate: transactionDate,
        status: status,
        amount: amount,
        currency: currency,
        canOpenSource: canOpenSource,
      ),
    );
  }
}

/// Stub consumer for `accounting.receivable.created`.
final class AccountingReceivableCreatedHistoryHandler {
  AccountingReceivableCreatedHistoryHandler({
    required IPartnerModule partnerModule,
  }) : _partnerModule = partnerModule;

  final IPartnerModule _partnerModule;

  Future<void> handle({
    required String tenantId,
    required String partnerId,
    required String sourceId,
    required String referenceCode,
    required DateTime transactionDate,
    required String status,
    double? amount,
    String? currency,
    bool canOpenSource = true,
  }) {
    return _partnerModule.executeCommandAsync(
      RecordPartnerHistoryCommand(
        tenantId: tenantId,
        partnerId: partnerId,
        role: PartnerRoleType.customer,
        transactionType: PartnerTransactionType.accountingReceivable,
        sourceModule: 'accounting',
        sourceId: sourceId,
        referenceCode: referenceCode,
        transactionDate: transactionDate,
        status: status,
        amount: amount,
        currency: currency,
        canOpenSource: canOpenSource,
      ),
    );
  }
}

/// Stub consumer for `accounting.payable.created`.
final class AccountingPayableCreatedHistoryHandler {
  AccountingPayableCreatedHistoryHandler({
    required IPartnerModule partnerModule,
  }) : _partnerModule = partnerModule;

  final IPartnerModule _partnerModule;

  Future<void> handle({
    required String tenantId,
    required String partnerId,
    required String sourceId,
    required String referenceCode,
    required DateTime transactionDate,
    required String status,
    double? amount,
    String? currency,
    bool canOpenSource = true,
  }) {
    return _partnerModule.executeCommandAsync(
      RecordPartnerHistoryCommand(
        tenantId: tenantId,
        partnerId: partnerId,
        role: PartnerRoleType.supplier,
        transactionType: PartnerTransactionType.accountingPayable,
        sourceModule: 'accounting',
        sourceId: sourceId,
        referenceCode: referenceCode,
        transactionDate: transactionDate,
        status: status,
        amount: amount,
        currency: currency,
        canOpenSource: canOpenSource,
      ),
    );
  }
}
