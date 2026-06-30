import 'package:test/test.dart';
import 'package:vet45_partner_domain/src/search/partner_search_criteria.dart';
import 'package:vet45_partner_domain/src/shared/entity_type.dart';
import 'package:vet45_partner_domain/src/shared/partner_status.dart';
import 'package:vet45_partner_domain/src/shared/profile_category.dart';

void main() {
  group('PartnerSearchCriteria', () {
    test('defaults to active only', () {
      final criteria = PartnerSearchCriteria();
      expect(criteria.statuses, {PartnerStatus.active});
      expect(criteria.activeOnly, isTrue);
    });

    test('expands organization profile category', () {
      final criteria = PartnerSearchCriteria(
        profileCategory: ProfileCategory.organization,
      );

      expect(
        criteria.expandedEntityTypes,
        {EntityType.householdBusiness, EntityType.company},
      );
    });

    test('trims keyword and converts blank to null', () {
      final criteria = PartnerSearchCriteria(keyword: '   ');
      expect(criteria.keyword, isNull);
    });
  });
}
