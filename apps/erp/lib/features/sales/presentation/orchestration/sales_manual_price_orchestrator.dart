import 'package:erp/features/sales/presentation.dart';

import '../lookups/sales_pricing_lookup.dart';
import '../lookups/sales_pricing_request_factory.dart';

abstract final class SalesManualPriceOrchestrator {
  static SalesManualPriceApplyFn bind() {
    return ({
      required SalesComposeState state,
      required SalesComposeLineVm line,
      required SalesManualPriceDraft draft,
      required SalesConfirmFn confirmBelowFloor,
      required SalesConfirmFn confirmOverwrite,
    }) async {
      try {
        var acknowledgedFloor = false;
        var evaluation = await SalesPricingLookup.bindEvaluate()(
          buildSalesManualPriceRequest(
            state: state,
            line: line,
            draft: draft,
            acknowledgeBelowFloor: false,
          ),
        );
        if (evaluation.requiresAcknowledgement) {
          acknowledgedFloor = await confirmBelowFloor();
          if (!acknowledgedFloor) {
            return const SalesManualPriceCancelled();
          }
          evaluation = await SalesPricingLookup.bindEvaluate()(
            buildSalesManualPriceRequest(
              state: state,
              line: line,
              draft: draft,
              acknowledgeBelowFloor: true,
            ),
          );
        }
        if (!evaluation.allowed) {
          return SalesManualPriceFailed(
            message:
                evaluation.message ??
                evaluation.blockingCode ??
                'Không thể áp dụng giá này.',
          );
        }

        final acceptedDraft = draft.withAcceptedUnitPrice(
          evaluation.normalizedUnitPrice,
        );
        if (acceptedDraft.saveAsPrivatePrice) {
          var saveResult = await SalesPricingLookup.bindSavePrivate()(
            buildSalesPrivatePriceSaveRequest(
              state: state,
              line: line,
              draft: acceptedDraft,
              acknowledgeFloorWarning: acknowledgedFloor,
              confirmOverwrite: false,
            ),
          );
          if (saveResult.overwriteConfirmationRequired) {
            final confirmed = await confirmOverwrite();
            if (!confirmed) {
              return const SalesManualPriceCancelled();
            }
            saveResult = await SalesPricingLookup.bindSavePrivate()(
              buildSalesPrivatePriceSaveRequest(
                state: state,
                line: line,
                draft: acceptedDraft,
                acknowledgeFloorWarning: acknowledgedFloor,
                confirmOverwrite: true,
              ),
            );
          }
          if (saveResult.overwriteConfirmationRequired) {
            return const SalesManualPriceFailed(
              message: 'Giá riêng đã thay đổi. Vui lòng thử lại.',
            );
          }
        }

        return SalesManualPriceApplied(
          acceptedDraft: acceptedDraft,
          savedPrivatePrice: acceptedDraft.saveAsPrivatePrice,
        );
      } on SalesExternalOperationException catch (error) {
        return SalesManualPriceFailed(message: error.message);
      }
    };
  }
}
