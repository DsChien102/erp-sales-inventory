import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/src/configuration/processing/generated/partner_access_metadata.g.dart';

void main() {
  group('partnerAccessMetadataRegistry', () {
    test('maps create duplicate query to partner.create', () {
      final metadata = partnerAccessMetadataRegistry.forType(
        CheckDuplicatePartnersQuery,
      );

      expect(metadata?.permission, PartnerPermissions.create);
      expect(metadata?.requiresTenant, isTrue);
    });

    test('maps update duplicate query to partner.update', () {
      final metadata = partnerAccessMetadataRegistry.forType(
        CheckDuplicatePartnersForUpdateQuery,
      );

      expect(metadata?.permission, PartnerPermissions.update);
      expect(metadata?.requiresTenant, isTrue);
    });
  });
}
