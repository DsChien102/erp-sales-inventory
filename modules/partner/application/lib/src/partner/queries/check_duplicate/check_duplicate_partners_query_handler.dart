import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_partner_duplicate_checker.dart';
import 'check_duplicate_partners_query.dart';
import 'partner_duplicate_match_dto.dart';

@QueryHandlerFor(CheckDuplicatePartnersQuery)
final class CheckDuplicatePartnersQueryHandler
    implements
        IQueryHandler<
          CheckDuplicatePartnersQuery,
          List<PartnerDuplicateMatchDto>
        > {
  CheckDuplicatePartnersQueryHandler({
    required IPartnerDuplicateChecker duplicateChecker,
  }) : _duplicateChecker = duplicateChecker;

  final IPartnerDuplicateChecker _duplicateChecker;

  @override
  Future<List<PartnerDuplicateMatchDto>> handle(
    CheckDuplicatePartnersQuery query,
  ) {
    return _duplicateChecker.checkDuplicates(query);
  }
}
