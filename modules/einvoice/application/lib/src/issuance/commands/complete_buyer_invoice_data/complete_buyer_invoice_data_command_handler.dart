import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_buyer_invoice_data_gateway.dart';
import '../../../shared/einvoice_blocked_codes.dart';
import '../../../shared/einvoice_blocked_exception.dart';
import '../../shared/effective_buyer_preview_dto.dart';
import 'complete_buyer_invoice_data_command.dart';
import 'complete_buyer_invoice_data_result.dart';

@CommandHandlerFor(CompleteBuyerInvoiceDataCommand)
final class CompleteBuyerInvoiceDataCommandHandler
    implements ICommandHandler<CompleteBuyerInvoiceDataCommand, BuyerCompletionResultDto> {
  CompleteBuyerInvoiceDataCommandHandler({
    required IBuyerInvoiceDataGateway gateway,
  }) : _gateway = gateway;

  final IBuyerInvoiceDataGateway _gateway;

  @override
  Future<BuyerCompletionResultDto> handle(
    CompleteBuyerInvoiceDataCommand command,
  ) async {
    final ctx = await _gateway.loadCompletionContext(
      tenantId: command.tenantId,
      actorId: command.actorId,
      salesOrderId: command.salesOrderId,
      expectedOrderVersion: command.expectedOrderVersion,
    );

    // Always apply the stored/resolved values to form EffectiveBuyerInvoiceData —
    // for a LOCKED completion resolved_values are frozen and MUST still be used
    // (DR-10 only forbids RE-resolving from Theme 03, not applying stored values).
    final effective = BuyerInvoiceDataResolver.resolve(
      base: ctx.base,
      completionSource: ctx.completionSource,
    );

    var locked = ctx.status == BuyerCompletionStatus.locked;
    if (!effective.isComplete) {
      // Org missing only tax code is the specific blocker (BR-14); otherwise generic.
      final code = effective.isMissingOnlyOrgTaxCode
          ? EInvoiceBlockedCodes.buyerTaxCodeRequired
          : effective.isMissingOnlyOrgAddress
          ? EInvoiceBlockedCodes.buyerAddressRequired
          : EInvoiceBlockedCodes.buyerDataIncomplete;
      throw EInvoiceBlockedException(code, message: 'Buyer data incomplete');
    }

    if (!locked) {
      // Persist ONLY the completion fields (§4.4.3) — the resolved value for each
      // eligible field. EffectiveBuyerInvoiceData is Runtime and never stored.
      String? fieldValue(String f) => switch (f) {
        'name' => effective.name,
        'email' => effective.email,
        'taxCode' => effective.taxCode,
        'address' => effective.address,
        _ => null,
      };
      final resolvedValues = <String, String?>{
        for (final f in ctx.eligibleFields) f: fieldValue(f),
      };
      await _gateway.saveLockedCompletion(
        tenantId: command.tenantId,
        actorId: command.actorId,
        salesOrderId: command.salesOrderId,
        salesOrderVersion: ctx.salesOrderVersion,
        eligibleFields: ctx.eligibleFields,
        resolvedValues: resolvedValues,
      );
      locked = true;
    }

    return BuyerCompletionResultDto(
      locked: locked,
      effectiveBuyer: EffectiveBuyerPreviewDto(
        name: effective.name,
        email: effective.email,
        taxCode: effective.taxCode,
        address: effective.address,
      ),
    );
  }
}
