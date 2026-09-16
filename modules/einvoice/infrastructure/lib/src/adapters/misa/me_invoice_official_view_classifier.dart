import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';

import 'me_invoice_provider_call_support.dart';

/// Classifies MISA `previewPublished` results for official invoice view.
abstract final class MeInvoiceOfficialViewClassifier {
  static OfficialViewProviderOutcome classify({
    required MeInvoiceResult<String> result,
    required String providerInvoiceReference,
    required DateTime now,
  }) {
    if (!result.isSuccess) {
      final error = result.error ?? 'unknown_error';
      MeInvoiceProviderCallSupport.throwIfTransportAmbiguous(error);
      if (MeInvoiceProviderCallSupport.isAuthOrConfigRejection(error)) {
        return OfficialViewProviderCheckRequired(
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
          providerReference: providerInvoiceReference,
        );
      }
      if (MeInvoiceProviderCallSupport.isEmptyProviderPayload(error)) {
        return OfficialViewProviderDefiniteFailure(
          failureCode: 'DOCUMENT_UNAVAILABLE',
          providerReference: providerInvoiceReference,
        );
      }
      return OfficialViewProviderCheckRequired(
        safeErrorCode: MeInvoiceProviderCallSupport.safeErrorCode(error),
        providerReference: providerInvoiceReference,
      );
    }

    final viewerUrl = MeInvoiceViewUrlPolicy.tryParse(result.data);
    if (viewerUrl == null) {
      return const OfficialViewProviderDefiniteFailure(
        failureCode: 'DOCUMENT_UNAVAILABLE',
      );
    }

    return OfficialViewProviderSuccess(
      viewerUrl: viewerUrl,
      expiresAt: now.add(
        const Duration(
          minutes: MeInvoiceProviderCallSupport.officialViewLeaseMinutes,
        ),
      ),
      providerReference: providerInvoiceReference,
    );
  }
}
