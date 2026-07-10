import '../partner_history/queries/get_partner_history/get_partner_history_query.dart';
import '../partner_history/queries/get_partner_history/partner_history_result_dto.dart';

/// Partner history read port — projection table / RPC.
abstract interface class IPartnerHistoryReadGateway {
  Future<PartnerHistoryResultDto> getPartnerHistory(
    GetPartnerHistoryQuery query,
  );
}
