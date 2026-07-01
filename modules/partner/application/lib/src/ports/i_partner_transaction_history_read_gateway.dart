import 'package:vet45_partner_domain/domain.dart';

import '../transaction_history/get_partner_transaction_history/partner_transaction_history_result_dto.dart';

abstract interface class IPartnerTransactionHistoryReadGateway {
  Future<PartnerTransactionHistoryResultDto> list({
    required String tenantId,
    required String partnerId,
    required PartnerTransactionHistoryCriteria criteria,
    int limit = 100,
    int offset = 0,
  });
}
