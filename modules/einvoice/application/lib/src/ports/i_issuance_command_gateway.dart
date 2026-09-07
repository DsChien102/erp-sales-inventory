import '../issuance/commands/issue_invoice/issue_invoice_result.dart';
import '../issuance/commands/issue_invoice/issue_invoice_start_request.dart';
import '../issuance/commands/retry_issuance/retry_issuance_start_request.dart';

abstract interface class IIssuanceCommandGateway {
  Future<IssueInvoiceResultDto> issueInvoice(IssueInvoiceStartRequest request);

  Future<IssueInvoiceResultDto> retryIssuance(RetryIssuanceStartRequest request);
}
