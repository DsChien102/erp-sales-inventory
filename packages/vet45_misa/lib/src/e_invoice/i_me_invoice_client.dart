import 'models/responses/send_email_result.dart';
import 'models/me_invoice_session_token.dart';
import 'models/me_invoice_result.dart';
import 'models/misa/invoice_data.dart';
import 'models/misa/invoice_status.dart';
import 'models/misa/template.dart';
import 'models/misa/ticket.dart';
import 'models/requests/invoice_publish_request.dart';
import 'models/requests/invoice_query.dart';
import 'models/requests/send_email_request.dart';
import 'models/responses/invoice_data_published.dart';
import 'models/responses/publish_invoice_result.dart';

/// Blackbox HTTP port for MISA meInvoice outbound (phát hành HĐĐT).
abstract interface class IMeInvoiceClient {
  Future<MeInvoiceResult<MeInvoiceSessionToken>> obtainAccessToken({
    bool forceLogin = false,
  });

  Future<MeInvoiceResult<List<MeInvoiceTemplate>>> listInvoiceTemplates({
    required bool invoiceWithCode,
    int? year,
  });

  Future<MeInvoiceResult<List<MeInvoiceTicket>>> listTicketTemplates({
    required bool invoiceWithCode,
    int? year,
  });

  Future<MeInvoiceResult<String>> previewUnpublished(
    MeInvoiceInvoiceData invoice,
  );

  Future<MeInvoiceResult<List<MeInvoicePublishInvoiceResultItem>>> publish(
    MeInvoicePublishRequest request,
  );

  Future<MeInvoiceResult<String>> previewPublished({
    required List<String> transactionIds,
    required String companyTaxCode,
    MeInvoiceInvoiceQuery? query,
  });

  Future<MeInvoiceResult<List<MeInvoiceInvoiceDataPublished>>> download({
    required List<String> transactionIds,
    required MeInvoiceInvoiceQuery query,
    required MeInvoiceDownloadDataType downloadDataType,
  });

  Future<MeInvoiceResult<List<MeInvoiceInvoiceStatus>>> getStatus({
    required List<String> ids,
    required MeInvoiceStatusInputType inputType,
    required MeInvoiceInvoiceQuery query,
  });

  Future<MeInvoiceResult<MeInvoiceSendEmailResponse>> sendEmail(
    MeInvoiceSendEmailRequest request,
  );

  Future<MeInvoiceResult<String>> convertToPaper({
    required List<String> transactionIds,
    required MeInvoiceInvoiceQuery query,
    required String converter,
    required String convertDate,
  });
}
