import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_misa/e_invoice.dart';

import 'me_invoice_provider_call_support.dart';

/// Classifies MISA `download` results for invoice document retrieval.
abstract final class MeInvoiceDocumentClassifier {
  static InvoiceDocumentProviderOutcome classify({
    required MeInvoiceResult<List<MeInvoiceInvoiceDataPublished>> result,
    required InvoiceDocumentType documentType,
    required String providerInvoiceReference,
  }) {
    if (!result.isSuccess) {
      final error = result.error ?? 'unknown_error';
      MeInvoiceProviderCallSupport.throwIfTransportAmbiguous(error);
      if (MeInvoiceProviderCallSupport.isAuthOrConfigRejection(error)) {
        return InvoiceDocumentProviderCheckRequired(
          safeErrorCode: 'PROVIDER_AUTH_FAILED',
          providerReference: providerInvoiceReference,
        );
      }
      if (MeInvoiceProviderCallSupport.isEmptyProviderPayload(error)) {
        return const InvoiceDocumentProviderDefiniteFailure(
          failureCode: 'DOCUMENT_UNAVAILABLE',
        );
      }
      return InvoiceDocumentProviderCheckRequired(
        safeErrorCode: MeInvoiceProviderCallSupport.safeErrorCode(error),
        providerReference: providerInvoiceReference,
      );
    }

    final items = result.data;
    if (items == null || items.isEmpty) {
      return const InvoiceDocumentProviderDefiniteFailure(
        failureCode: 'DOCUMENT_UNAVAILABLE',
      );
    }

    final item = items.first;
    if (item.transactionId.trim().isNotEmpty &&
        item.transactionId != providerInvoiceReference) {
      return InvoiceDocumentProviderCheckRequired(
        safeErrorCode: 'PROVIDER_IDENTITY_MISMATCH',
        providerReference: providerInvoiceReference,
      );
    }

    final bytes = item.bytes ?? const <int>[];
    if (bytes.isEmpty) {
      return const InvoiceDocumentProviderDefiniteFailure(
        failureCode: 'DOCUMENT_UNAVAILABLE',
      );
    }

    final validationError = InvoiceDocumentContentPolicy.validate(
      type: documentType,
      bytes: bytes,
    );
    if (validationError != null) {
      return InvoiceDocumentProviderCheckRequired(
        safeErrorCode: validationError,
        providerReference: providerInvoiceReference,
      );
    }

    return InvoiceDocumentProviderSuccess(
      bytes: bytes,
      providerReference: providerInvoiceReference,
    );
  }
}
