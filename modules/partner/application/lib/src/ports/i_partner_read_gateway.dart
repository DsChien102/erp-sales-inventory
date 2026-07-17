import '../partner/queries/check_delete_eligibility/check_delete_eligibility_query.dart';
import '../partner/queries/check_delete_eligibility/delete_eligibility_dto.dart';
import '../partner/queries/get_partner_detail/get_partner_detail_query.dart';
import '../partner/queries/get_partner_detail/partner_detail_dto.dart';
import '../partner/queries/search_partners/partner_search_result_dto.dart';
import '../partner/queries/search_partners/search_partners_query.dart';
import '../partner_action_log/queries/get_partner_action_logs/get_partner_action_logs_query.dart';
import '../partner_action_log/queries/get_partner_action_logs/partner_action_log_result_dto.dart';
import '../partner_history/queries/get_partner_history/get_partner_history_query.dart';
import '../partner_history/queries/get_partner_history/partner_history_result_dto.dart';

/// Read port — infrastructure implements via Supabase RPC / views.
abstract interface class IPartnerReadGateway {
  Future<PartnerSearchResultDto> searchPartners(SearchPartnersQuery query);

  Future<PartnerDetailDto> getPartnerDetail(GetPartnerDetailQuery query);

  Future<DeleteEligibilityDto> checkDeleteEligibility(
    CheckDeleteEligibilityQuery query,
  );

  Future<PartnerHistoryResultDto> getPartnerHistory(
    GetPartnerHistoryQuery query,
  );

  Future<PartnerActionLogResultDto> getPartnerActionLogs(
    GetPartnerActionLogsQuery query,
  );
}
