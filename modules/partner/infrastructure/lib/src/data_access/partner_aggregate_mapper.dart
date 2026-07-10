import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Hydrates domain aggregates from read-model DTOs.
abstract final class PartnerAggregateMapper {
  static Partner fromDetail({
    required PartnerDetailDto detail,
    required TenantId tenantId,
  }) {
    return Partner.reconstitute(
      id: PartnerId(detail.partnerId),
      tenantId: tenantId,
      partnerType: detail.partnerType,
      status: detail.status,
      displayName: detail.displayName,
      roles: detail.roles.map((r) => PartnerRole(role: r)).toList(),
      personProfile: detail.personProfile == null
          ? null
          : PersonProfile(
              title: detail.personProfile!.title,
              fullName: detail.personProfile!.fullName,
              nickname: detail.personProfile!.nickname,
              phone: PhoneNumber(detail.personProfile!.phone),
              phone2: detail.personProfile!.phone2 == null
                  ? null
                  : PhoneNumber(detail.personProfile!.phone2!),
              email: detail.personProfile!.email == null
                  ? null
                  : EmailAddress(detail.personProfile!.email!),
              taxCode: detail.personProfile!.taxCode == null
                  ? null
                  : TaxCode(detail.personProfile!.taxCode!),
              note: detail.personProfile!.note,
            ),
      organizationProfile: detail.organizationProfile == null
          ? null
          : OrganizationProfile(
              organizationType: detail.organizationProfile!.organizationType,
              organizationName: detail.organizationProfile!.organizationName,
              shortName: detail.organizationProfile!.shortName,
              intlName: detail.organizationProfile!.intlName,
              phone: PhoneNumber(detail.organizationProfile!.phone),
              email: detail.organizationProfile!.email == null
                  ? null
                  : EmailAddress(detail.organizationProfile!.email!),
              taxCode: detail.organizationProfile!.taxCode == null
                  ? null
                  : TaxCode(detail.organizationProfile!.taxCode!),
              companyAddress: detail.organizationProfile!.companyAddress,
              note: detail.organizationProfile!.note,
            ),
      contacts: detail.contacts
          .map(
            (c) => OrganizationContact(
              personPartnerId: PartnerId(c.personPartnerId),
              contactRole: c.contactRole,
              isPrimary: c.isPrimary,
            ),
          )
          .toList(growable: false),
      version: detail.expectedVersion,
    );
  }
}
