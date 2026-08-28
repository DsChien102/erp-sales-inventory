import '../issuance/commands/issue_invoice/issue_invoice_result.dart';
import '../issuance/commands/issue_invoice/issue_invoice_start_request.dart';

abstract interface class IIssuanceCommandGateway {
  Future<IssueInvoiceResultDto> issueInvoice(IssueInvoiceStartRequest request);
}
