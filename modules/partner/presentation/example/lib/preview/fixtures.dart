import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

/// Shared fake DTOs for the Partner presentation example catalog.
abstract final class PartnerPreviewFixtures {
  static final personActive = PartnerDetailDto(
    partnerId: 'preview-person-1',
    partnerType: PartnerType.person,
    status: PartnerStatus.active,
    displayName: 'Nguyễn Văn A',
    roles: const [PartnerRoleType.customer],
    availableActions: const [
      PartnerAvailableAction.update,
      PartnerAvailableAction.transform,
      PartnerAvailableAction.deactivate,
      PartnerAvailableAction.delete,
      PartnerAvailableAction.viewHistory,
    ],
    expectedVersion: 1,
    createdAt: DateTime.utc(2026, 1, 10, 9),
    updatedAt: DateTime.utc(2026, 2, 20, 14, 15),
    personProfile: PersonProfileDto(
      title: PersonTitle('Ông'),
      fullName: 'Nguyễn Văn A',
      phone: '0901234567',
      email: 'nguyenvana@example.com',
      taxCode: '0101234567',
      invoice: const InvoiceProfileInput(
        invoiceName: 'Nguyễn Văn A',
        invoiceEmail: 'invoice@example.com',
        invoiceAddress: '12 Nguyễn Huệ, Quận 1, TP.HCM',
      ),
      delivery: const DeliveryAddressInput(
        province: 'Thành phố Hồ Chí Minh',
        commune: 'Phường Bến Nghé',
        address: '12 Nguyễn Huệ',
      ),
      note: 'Giao buổi sáng.',
    ),
  );

  static final personInactive = PartnerDetailDto(
    partnerId: 'preview-person-inactive',
    partnerType: PartnerType.person,
    status: PartnerStatus.inactive,
    displayName: 'Trần Thị B',
    roles: const [PartnerRoleType.supplier],
    availableActions: const [
      PartnerAvailableAction.update,
      PartnerAvailableAction.reactivate,
      PartnerAvailableAction.delete,
    ],
    expectedVersion: 2,
    personProfile: const PersonProfileDto(
      fullName: 'Trần Thị B',
      phone: '0987654321',
    ),
  );

  static const organizationWithContacts = PartnerDetailDto(
    partnerId: 'preview-org-1',
    partnerType: PartnerType.organization,
    status: PartnerStatus.active,
    displayName: 'Công ty ABC',
    roles: [PartnerRoleType.customer, PartnerRoleType.supplier],
    availableActions: [
      PartnerAvailableAction.update,
      PartnerAvailableAction.manageContacts,
      PartnerAvailableAction.deactivate,
      PartnerAvailableAction.delete,
      PartnerAvailableAction.viewHistory,
    ],
    expectedVersion: 1,
    organizationProfile: OrganizationProfileDto(
      organizationType: OrganizationType.company,
      organizationName: 'Công ty ABC',
      phone: '0901234567',
      email: 'contact@abc.vn',
      taxCode: '0312345678',
      invoice: InvoiceProfileInput(
        invoiceName: 'Công ty ABC',
        invoiceEmail: 'accounting@abc.vn',
        invoiceAddress: '1 Lê Lợi, Quận 1, TP.HCM',
      ),
      delivery: DeliveryAddressInput(
        province: 'Thành phố Hồ Chí Minh',
        commune: 'Phường Bến Nghé',
        address: '1 Lê Lợi',
      ),
      note: 'Ưu tiên giao T2–T6.',
    ),
    contacts: [
      PartnerContactDto(
        personPartnerId: 'p-contact-1',
        displayName: 'Trần Thị B',
        title: 'Chị',
        phone: '0907654321',
        phone2: '0281111222',
        email: 'tranthib@abc.vn',
        contactRole: 'Kế toán',
        isPrimary: true,
      ),
      PartnerContactDto(
        personPartnerId: 'p-contact-2',
        displayName: 'Lê Văn C',
        phone: '0911222333',
        contactRole: 'Kinh doanh',
        isPrimary: false,
      ),
    ],
  );

  static const listActive = PartnerListItemDto(
    partnerId: 'preview-list-1',
    displayName: 'Công ty TNHH Agapi Demo',
    partnerType: PartnerType.organization,
    status: PartnerStatus.active,
    roles: [PartnerRoleType.customer, PartnerRoleType.supplier],
    phone: '0901 234 567',
    taxCode: '0312345678',
  );

  static const listInactive = PartnerListItemDto(
    partnerId: 'preview-list-2',
    displayName: 'Nguyễn Văn A',
    partnerType: PartnerType.person,
    status: PartnerStatus.inactive,
    roles: [PartnerRoleType.customer],
    phone: '0987 654 321',
  );

  static const primaryContact = PartnerContactDto(
    personPartnerId: 'p-contact-1',
    displayName: 'Trần Thị B',
    title: 'Chị',
    phone: '0907654321',
    email: 'tranthib@abc.vn',
    contactRole: 'Kế toán',
    isPrimary: true,
  );

  static const transformOrganization = OrganizationProfileInput(
    organizationType: OrganizationType.company,
    organizationName: 'Công ty TNHH An Phát',
    shortName: 'An Phát',
    phone: '028 3822 5511',
    email: 'info@anphat.vn',
  );

  static const duplicateMatches = <PartnerDuplicateMatchDto>[
    PartnerDuplicateMatchDto(
      partnerId: 'dup-1',
      displayName: 'Nguyễn Văn A',
      matchedField: PartnerDuplicateMatchField.phone,
      matchLevel: PartnerDuplicateMatchLevel.possible,
      partnerType: PartnerType.person,
      matchedValue: '0901234567',
    ),
    PartnerDuplicateMatchDto(
      partnerId: 'dup-2',
      displayName: 'Công ty A',
      matchedField: PartnerDuplicateMatchField.taxCode,
      matchLevel: PartnerDuplicateMatchLevel.exact,
      partnerType: PartnerType.organization,
      matchedValue: '0312345678',
    ),
  ];

  static const sampleWards = <VnWard>[
    VnWard(
      code: '26734',
      fullName: 'Phường Bến Nghé',
      provinceCode: '79',
    ),
    VnWard(
      code: '26740',
      fullName: 'Phường Đa Kao',
      provinceCode: '79',
    ),
    VnWard(
      code: '26737',
      fullName: 'Phường Nguyễn Thái Bình',
      provinceCode: '79',
    ),
  ];
}
