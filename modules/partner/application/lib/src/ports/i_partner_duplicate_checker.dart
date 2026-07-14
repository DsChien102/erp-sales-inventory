import '../partner/queries/check_duplicate/check_duplicate_partners_query.dart';
import '../partner/queries/check_duplicate/partner_duplicate_match_dto.dart';

/// Duplicate-check port — infrastructure implements via `partner.check_duplicate`.
abstract interface class IPartnerDuplicateChecker {
  Future<List<PartnerDuplicateMatchDto>> checkDuplicates(
    CheckDuplicatePartnersQuery query,
  );
}
