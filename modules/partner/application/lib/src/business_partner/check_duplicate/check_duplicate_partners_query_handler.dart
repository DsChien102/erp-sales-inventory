import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

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
  ) async {
    final matches = await _duplicateChecker.findMatches(
      tenantId: TenantId(query.tenantId),
      phone: _optionalPhone(query.phone),
      email: _optionalEmail(query.email),
      taxCode: _optionalTaxCode(query.taxCode),
      excludePartnerId: query.excludePartnerId == null
          ? null
          : BusinessPartnerId(query.excludePartnerId!),
    );

    return matches
        .map(PartnerDuplicateMatchDto.fromDomain)
        .toList(growable: false);
  }

  PhoneNumber? _optionalPhone(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return PhoneNumber(trimmed);
  }

  EmailAddress? _optionalEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return EmailAddress(trimmed);
  }

  TaxCode? _optionalTaxCode(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return TaxCode(trimmed);
  }
}
