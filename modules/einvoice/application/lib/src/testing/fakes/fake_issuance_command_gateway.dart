import 'package:vet45_einvoice_domain/domain.dart';

import '../../issuance/commands/issue_invoice/issue_invoice_result.dart';
import '../../issuance/commands/issue_invoice/issue_invoice_start_request.dart';
import '../../issuance/commands/retry_issuance/retry_issuance_start_request.dart';
import '../../ports/i_issuance_command_gateway.dart';

final class FakeIssuanceCommandGateway implements IIssuanceCommandGateway {
  FakeIssuanceCommandGateway({required IssueInvoiceResultDto result}) : _result = result;

  FakeIssuanceCommandGateway.processing()
    : _result = const IssueInvoiceResultDto(
        issuanceId: 'iss-1',
        attemptId: 'att-1',
        status: IssuanceAttemptStatus.preparing,
      );

  FakeIssuanceCommandGateway.retryPreparing()
    : _result = const IssueInvoiceResultDto(
        issuanceId: 'iss-1',
        attemptId: 'att-1',
        status: IssuanceAttemptStatus.preparing,
      );

  IssueInvoiceStartRequest? lastRequest;
  RetryIssuanceStartRequest? lastRetry;
  final IssueInvoiceResultDto _result;

  @override
  Future<IssueInvoiceResultDto> issueInvoice(
    IssueInvoiceStartRequest request,
  ) async {
    lastRequest = request;
    return _result;
  }

  @override
  Future<IssueInvoiceResultDto> retryIssuance(
    RetryIssuanceStartRequest request,
  ) async {
    lastRetry = request;
    return _result;
  }
}
