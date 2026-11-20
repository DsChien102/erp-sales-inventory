// Test giữ hành vi 4-A (H1, H2): tham số RPC và cách đọc kết quả của partner.
//
// `PartnerRepository` phải ra đúng các map viết tay ở đây (từng khớp mapper cũ của
// module partner, đã xoá ở 4-C). Không sửa map mong đợi cho khớp code mới.
import 'package:erp/features/partner/data/models/partner_enums.dart';
import 'package:erp/features/partner/data/models/partner_inputs.dart';
import 'package:erp/features/partner/data/models/person_title.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_rpc.dart';

// ---------------------------------------------------------------------------
// Map mong đợi (viết tay) cho phần hồ sơ gửi lên.
// ---------------------------------------------------------------------------

const Map<String, dynamic> kPersonJson = {
  'title': 'Anh',
  'full_name': 'Nguyễn Văn A',
  'nickname': 'A',
  'phone': '0901234567',
  'phone2': '0907654321',
  'email': 'a@example.com',
  'tax_code': '0101234567',
  'invoice': {
    'name': 'Cty A',
    'address': '1 Lê Lợi',
    'email': 'inv@example.com',
  },
  'invoice_name': 'Cty A',
  'invoice_address': '1 Lê Lợi',
  'invoice_email': 'inv@example.com',
  'delivery': {
    'province': 'Hà Nội',
    'commune': 'Phường 1',
    'address': '2 Trần Phú',
  },
  'delivery_province': 'Hà Nội',
  'delivery_commune': 'Phường 1',
  'delivery_address': '2 Trần Phú',
  'note': 'ghi chú',
};

const Map<String, dynamic> kContactJson = {
  'title': null,
  'full_name': 'Trần Thị B',
  'nickname': null,
  'phone': '0912345678',
  'phone2': null,
  'email': null,
  'tax_code': null,
  'invoice': null,
  'invoice_name': null,
  'invoice_address': null,
  'invoice_email': null,
  'delivery': null,
  'delivery_province': null,
  'delivery_commune': null,
  'delivery_address': null,
  'note': null,
};

const Map<String, dynamic> kOrganizationJson = {
  'organization_type': 'business_household',
  'organization_name': 'Hộ KD Bình',
  'short_name': 'Bình',
  'intl_name': null,
  'phone': '0281234567',
  'email': 'org@example.com',
  'tax_code': '0101234567-001',
  'company_address': '3 Nguyễn Huệ',
  'invoice': null,
  'invoice_name': null,
  'invoice_address': null,
  'invoice_email': null,
  'delivery': {'province': null, 'commune': null, 'address': 'Kho 1'},
  'delivery_province': null,
  'delivery_commune': null,
  'delivery_address': 'Kho 1',
  'note': null,
};

// ---------------------------------------------------------------------------
// Mô tả DTO bằng map thuần.
// ---------------------------------------------------------------------------

Map<String, Object?>? _invoice(dynamic i) => i == null
    ? null
    : {
        'invoiceName': i.invoiceName,
        'invoiceAddress': i.invoiceAddress,
        'invoiceEmail': i.invoiceEmail,
      };

Map<String, Object?>? _delivery(dynamic d) => d == null
    ? null
    : {
        'province': d.province,
        'commune': d.commune,
        'address': d.address,
      };

Map<String, Object?>? describePersonProfile(dynamic p) => p == null
    ? null
    : {
        'title': p.title?.value,
        'fullName': p.fullName,
        'nickname': p.nickname,
        'phone': p.phone,
        'phone2': p.phone2,
        'email': p.email,
        'taxCode': p.taxCode,
        'invoice': _invoice(p.invoice),
        'delivery': _delivery(p.delivery),
        'note': p.note,
      };

Map<String, Object?>? describeOrganizationProfile(dynamic o) => o == null
    ? null
    : {
        'organizationType': (o.organizationType as Enum).name,
        'organizationName': o.organizationName,
        'shortName': o.shortName,
        'intlName': o.intlName,
        'phone': o.phone,
        'email': o.email,
        'taxCode': o.taxCode,
        'companyAddress': o.companyAddress,
        'invoice': _invoice(o.invoice),
        'delivery': _delivery(o.delivery),
        'note': o.note,
      };

Map<String, Object?> describeDetail(dynamic d) => {
  'partnerId': d.partnerId,
  'partnerType': (d.partnerType as Enum).name,
  'status': (d.status as Enum).name,
  'displayName': d.displayName,
  'roles': [for (final r in d.roles as List) (r as Enum).name],
  'availableActions': [
    for (final a in d.availableActions as List) (a as Enum).name,
  ],
  'expectedVersion': d.expectedVersion,
  'personProfile': describePersonProfile(d.personProfile),
  'organizationProfile': describeOrganizationProfile(d.organizationProfile),
  'contacts': [
    for (final c in d.contacts as List)
      {
        'personPartnerId': c.personPartnerId,
        'displayName': c.displayName,
        'title': c.title,
        'phone': c.phone,
        'phone2': c.phone2,
        'email': c.email,
        'contactRole': c.contactRole,
        'isPrimary': c.isPrimary,
        'status': (c.status as Enum).name,
        'note': c.note,
      },
  ],
  'primaryContactOrganizationId': d.primaryContactOrganizationId,
  'primaryContactOrganizationName': d.primaryContactOrganizationName,
  'createdAt': (d.createdAt as DateTime?)?.toIso8601String(),
  'updatedAt': (d.updatedAt as DateTime?)?.toIso8601String(),
};

Map<String, Object?> describeSearch(dynamic r) => {
  'items': [
    for (final i in r.items as List)
      {
        'partnerId': i.partnerId,
        'partnerType': (i.partnerType as Enum).name,
        'status': (i.status as Enum).name,
        'displayName': i.displayName,
        'phone': i.phone,
        'email': i.email,
        'taxCode': i.taxCode,
        'updatedAt': (i.updatedAt as DateTime?)?.toIso8601String(),
        'roles': [for (final role in i.roles as List) (role as Enum).name],
      },
  ],
  'total': r.total,
  'page': r.page,
  'limit': r.limit,
};

List<Map<String, Object?>> describeDuplicates(List<dynamic> list) => [
  for (final m in list)
    {
      'partnerId': m.partnerId,
      'displayName': m.displayName,
      'matchedField': (m.matchedField as Enum).name,
      'matchLevel': (m.matchLevel as Enum).name,
      'partnerType': (m.partnerType as Enum).name,
      'matchedValue': m.matchedValue,
    },
];

Map<String, Object?> describeWarnings(dynamic r) => {
  for (final w in r.warnings as List) '${w.code}/${w.field}': w.message,
};

// ---------------------------------------------------------------------------
// JSON kết quả mẫu và kết quả mong đợi (viết tay).
// ---------------------------------------------------------------------------

const Map<String, dynamic> kOrgDetailJson = {
  'partner_id': 'p-org',
  'partner_type': 'organization',
  'status': 'active',
  'display_name': 'Cty ABC',
  'roles': ['customer', 'supplier'],
  'available_actions': ['update', 'manageContacts', 'viewHistory'],
  'expected_version': 3,
  'person_profile': null,
  'organization_profile': {
    'organization_type': 'businessHousehold',
    'organization_name': 'Cty ABC',
    'short_name': null,
    'intl_name': null,
    'phone': '0281234567',
    'email': null,
    'tax_code': '0101234567',
    'company_address': '3 Nguyễn Huệ',
    'invoice': <String, dynamic>{},
    'delivery': {'province': 'HN', 'commune': null, 'address': '  '},
    'note': null,
  },
  'contacts': [
    {
      'person_partner_id': 'c-1',
      'display_name': 'Trần B',
      'title': 'Chị',
      'phone': '0901',
      'phone2': null,
      'email': null,
      'contact_role': 'primary',
      'is_primary': true,
      'status': 'inactive',
      'note': 'n',
    },
    {
      'person_partner_id': 'c-2',
      'display_name': 'Lê C',
      'contact_role': ' Kế toán ',
      'is_primary': null,
    },
  ],
  'primary_contact_organization_id': null,
  'primary_contact_organization_name': null,
  'created_at': '2026-10-01T10:00:00Z',
  'updated_at': null,
};

const Map<String, Object?> kOrgDetailExpected = {
  'partnerId': 'p-org',
  'partnerType': 'organization',
  'status': 'active',
  'displayName': 'Cty ABC',
  'roles': ['customer', 'supplier'],
  'availableActions': ['update', 'manageContacts', 'viewHistory'],
  'expectedVersion': 3,
  'personProfile': null,
  'organizationProfile': {
    'organizationType': 'businessHousehold',
    'organizationName': 'Cty ABC',
    'shortName': null,
    'intlName': null,
    'phone': '0281234567',
    'email': null,
    'taxCode': '0101234567',
    'companyAddress': '3 Nguyễn Huệ',
    'invoice': null,
    'delivery': {'province': 'HN', 'commune': null, 'address': null},
    'note': null,
  },
  'contacts': [
    {
      'personPartnerId': 'c-1',
      'displayName': 'Trần B',
      'title': 'Chị',
      'phone': '0901',
      'phone2': null,
      'email': null,
      'contactRole': null,
      'isPrimary': true,
      'status': 'inactive',
      'note': 'n',
    },
    {
      'personPartnerId': 'c-2',
      'displayName': 'Lê C',
      'title': null,
      'phone': null,
      'phone2': null,
      'email': null,
      'contactRole': 'Kế toán',
      'isPrimary': false,
      'status': 'active',
      'note': null,
    },
  ],
  'primaryContactOrganizationId': null,
  'primaryContactOrganizationName': null,
  'createdAt': '2026-10-01T10:00:00.000Z',
  'updatedAt': null,
};

const Map<String, dynamic> kPersonDetailJson = {
  'partner_id': 'p-per',
  'partner_type': 'person',
  'status': 'inactive',
  'display_name': 'Nguyễn Văn A',
  'roles': ['customer'],
  'expected_version': 7,
  'person_profile': {
    'title': 'Anh',
    'full_name': 'Nguyễn Văn A',
    'nickname': null,
    'phone': '0901234567',
    'phone2': null,
    'email': 'a@example.com',
    'tax_code': null,
    'invoice': {'invoice_name': 'X', 'invoice_email': ' e@x.vn '},
    'delivery': {'province': 'HCM', 'commune': 'Q1', 'address': 'Số 1'},
    'note': null,
  },
  'organization_profile': null,
  'primary_contact_organization_id': 'org-1',
  'primary_contact_organization_name': 'Cty ABC',
  'created_at': '2026-10-01T10:00:00Z',
  'updated_at': '2026-10-02T11:30:00Z',
};

const Map<String, Object?> kPersonDetailExpected = {
  'partnerId': 'p-per',
  'partnerType': 'person',
  'status': 'inactive',
  'displayName': 'Nguyễn Văn A',
  'roles': ['customer'],
  'availableActions': <String>[],
  'expectedVersion': 7,
  'personProfile': {
    'title': 'Anh',
    'fullName': 'Nguyễn Văn A',
    'nickname': null,
    'phone': '0901234567',
    'phone2': null,
    'email': 'a@example.com',
    'taxCode': null,
    'invoice': {
      'invoiceName': 'X',
      'invoiceAddress': null,
      'invoiceEmail': 'e@x.vn',
    },
    'delivery': {'province': 'HCM', 'commune': 'Q1', 'address': 'Số 1'},
    'note': null,
  },
  'organizationProfile': null,
  'contacts': <Object>[],
  'primaryContactOrganizationId': 'org-1',
  'primaryContactOrganizationName': 'Cty ABC',
  'createdAt': '2026-10-01T10:00:00.000Z',
  'updatedAt': '2026-10-02T11:30:00.000Z',
};

const Map<String, dynamic> kSearchJson = {
  'items': [
    {
      'partner_id': 'p-1',
      'partner_type': 'person',
      'status': 'active',
      'display_name': 'Nguyễn Văn A',
      'phone': '0901234567',
      'email': null,
      'tax_code': null,
      'updated_at': '2026-10-02T11:30:00Z',
      'roles': ['customer'],
    },
    {
      'partner_id': 'p-2',
      'partner_type': 'organization',
      'status': 'inactive',
      'display_name': 'Cty ABC',
      'updated_at': null,
      'roles': ['customer', 'supplier'],
    },
  ],
};

const Map<String, Object?> kSearchExpected = {
  'items': [
    {
      'partnerId': 'p-1',
      'partnerType': 'person',
      'status': 'active',
      'displayName': 'Nguyễn Văn A',
      'phone': '0901234567',
      'email': null,
      'taxCode': null,
      'updatedAt': '2026-10-02T11:30:00.000Z',
      'roles': ['customer'],
    },
    {
      'partnerId': 'p-2',
      'partnerType': 'organization',
      'status': 'inactive',
      'displayName': 'Cty ABC',
      'phone': null,
      'email': null,
      'taxCode': null,
      'updatedAt': null,
      'roles': ['customer', 'supplier'],
    },
  ],
  'total': 2,
  'page': 1,
  'limit': 2,
};

const Map<String, Object?> kSearchEmptyExpected = {
  'items': <Object>[],
  'total': 0,
  'page': 1,
  'limit': 0,
};

const List<Map<String, dynamic>> kDuplicateRows = [
  {
    'partner_id': 'd-1',
    'display_name': 'Cty ABC',
    'matched_field': 'tax_code',
    'partner_type': 'organization',
    'matched_value': '0101234567',
  },
  {
    'partner_id': 'd-2',
    'display_name': 'Nguyễn Văn A',
    'matched_field': 'name',
    'partner_type': 'person',
  },
  {
    'partner_id': 'd-3',
    'display_name': 'Lê C',
    'matched_field': 'phone',
    'partner_type': 'person',
    'matched_value': '0901',
  },
  {
    'partner_id': 'd-4',
    'display_name': 'Mai D',
    'matched_field': 'email',
    'partner_type': 'person',
    'matched_value': 'd@x.vn',
  },
];

const List<Map<String, Object?>> kDuplicateExpected = [
  {
    'partnerId': 'd-1',
    'displayName': 'Cty ABC',
    'matchedField': 'taxCode',
    'matchLevel': 'exact',
    'partnerType': 'organization',
    'matchedValue': '0101234567',
  },
  {
    'partnerId': 'd-2',
    'displayName': 'Nguyễn Văn A',
    'matchedField': 'name',
    'matchLevel': 'possible',
    'partnerType': 'person',
    'matchedValue': null,
  },
  {
    'partnerId': 'd-3',
    'displayName': 'Lê C',
    'matchedField': 'phone',
    'matchLevel': 'exact',
    'partnerType': 'person',
    'matchedValue': '0901',
  },
  {
    'partnerId': 'd-4',
    'displayName': 'Mai D',
    'matchedField': 'email',
    'matchLevel': 'exact',
    'partnerType': 'person',
    'matchedValue': 'd@x.vn',
  },
];

/// Tham số mong đợi của từng RPC (tên RPC → map). Dùng chung cho các nhóm test.
const Map<String, dynamic> kCreatePersonParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_partner_type': 'person',
  'p_roles': ['customer', 'supplier'],
  'p_person_profile': kPersonJson,
  'p_organization_profile': null,
  'p_organization_primary_contact': null,
  'p_confirm_duplicate': false,
};

const Map<String, dynamic> kCreateOrgParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_partner_type': 'organization',
  'p_roles': ['supplier'],
  'p_person_profile': null,
  'p_organization_profile': kOrganizationJson,
  'p_organization_primary_contact': kContactJson,
  'p_confirm_duplicate': true,
};

const Map<String, dynamic> kUpdatePersonParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_partner_id': 'p-1',
  'p_roles': ['customer'],
  'p_person_profile': kPersonJson,
  'p_organization_profile': null,
  'p_confirm_duplicate': false,
  'p_expected_version': 3,
};

const Map<String, dynamic> kUpdateOrgParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_partner_id': 'p-2',
  'p_roles': ['customer', 'supplier'],
  'p_person_profile': null,
  'p_organization_profile': kOrganizationJson,
  'p_confirm_duplicate': true,
  'p_expected_version': 5,
};

const Map<String, dynamic> kTransformParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_partner_id': 'p-1',
  'p_organization_profile': kOrganizationJson,
  'p_expected_version': 4,
  'p_confirm_duplicate': false,
};

const Map<String, dynamic> kAddContactExistingParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_organization_partner_id': 'org-1',
  'p_person_partner_id': 'per-1',
  'p_new_person_profile': null,
  'p_contact_role': null,
  'p_is_primary': false,
};

const Map<String, dynamic> kAddContactNewParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_organization_partner_id': 'org-1',
  'p_person_partner_id': null,
  'p_new_person_profile': kContactJson,
  'p_contact_role': 'Kế toán',
  'p_is_primary': true,
};

const Map<String, dynamic> kUpdateContactParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_organization_partner_id': 'org-1',
  'p_person_partner_id': 'per-1',
  'p_contact_role': 'Giám đốc',
  'p_is_primary': true,
  'p_note': 'ghi chú',
  'p_person_profile': kPersonJson,
};

const Map<String, dynamic> kRemoveContactParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_organization_partner_id': 'org-1',
  'p_person_partner_id': 'per-1',
};

const Map<String, dynamic> kStatusParams = {
  'p_tenant_id': 't-1',
  'p_actor_id': 'u-1',
  'p_partner_id': 'p-1',
  'p_reason': 'Không còn giao dịch',
  'p_expected_version': 2,
};

const Map<String, dynamic> kSearchBothParams = {
  'p_tenant_id': 't-1',
  'p_query': 'abc',
  'p_partner_type': 'organization',
  'p_role': 'both',
  'p_status': 'active',
  'p_updated_within_days': 30,
  'p_page': 2,
  'p_limit': 40,
  'p_sort': 'name_asc',
};

const Map<String, dynamic> kSearchAnyParams = {
  'p_tenant_id': 't-1',
  'p_query': null,
  'p_partner_type': null,
  'p_role': 'any',
  'p_status': 'active',
  'p_updated_within_days': null,
  'p_page': 1,
  'p_limit': 30,
  'p_sort': null,
};

const Map<String, dynamic> kSearchRoleParams = {
  'p_tenant_id': 't-1',
  'p_query': null,
  'p_partner_type': 'person',
  'p_role': 'supplier',
  'p_status': null,
  'p_updated_within_days': null,
  'p_page': 1,
  'p_limit': 20,
  'p_sort': null,
};

const Map<String, dynamic> kSearchPlainParams = {
  'p_tenant_id': 't-1',
  'p_query': null,
  'p_partner_type': null,
  'p_role': null,
  'p_status': null,
  'p_updated_within_days': null,
  'p_page': 1,
  'p_limit': 20,
  'p_sort': null,
};

const Map<String, dynamic> kDetailParams = {
  'p_tenant_id': 't-1',
  'p_partner_id': 'p-1',
};

const Map<String, dynamic> kDuplicateParams = {
  'p_tenant_id': 't-1',
  'p_phone': '0901234567',
  'p_email': 'a@example.com',
  'p_tax_code': '0101234567',
  'p_name': 'Nguyễn Văn A',
  'p_exclude_partner_id': 'p-9',
};

void main() {
  group('PartnerRepository ra cùng tham số và đọc cùng kết quả (H1, H2)', () {
    PersonProfileInput person() => PersonProfileInput(
      title: PersonTitle('Anh'),
      fullName: 'Nguyễn Văn A',
      nickname: 'A',
      phone: '0901234567',
      phone2: '0907654321',
      email: 'a@example.com',
      taxCode: '0101234567',
      invoice: const InvoiceProfileInput(
        invoiceName: 'Cty A',
        invoiceAddress: '1 Lê Lợi',
        invoiceEmail: 'inv@example.com',
      ),
      delivery: const DeliveryAddressInput(
        province: 'Hà Nội',
        commune: 'Phường 1',
        address: '2 Trần Phú',
      ),
      note: 'ghi chú',
    );
    const contact = PersonProfileInput(fullName: 'Trần Thị B', phone: '0912345678');
    const organization = OrganizationProfileInput(
      organizationType: OrganizationType.businessHousehold,
      organizationName: 'Hộ KD Bình',
      shortName: 'Bình',
      phone: '0281234567',
      email: 'org@example.com',
      taxCode: '0101234567-001',
      companyAddress: '3 Nguyễn Huệ',
      delivery: DeliveryAddressInput(address: 'Kho 1'),
    );

    ({PartnerRepository repo, RecordingRpc rpc}) make(
      dynamic Function(String fn, Map<String, dynamic>? params)? respond,
    ) {
      final rpc = RecordingRpc(respond: respond);
      return (
        repo: PartnerRepository(
          rpc: rpc,
          tenantId: () async => 't-1',
          actorId: () async => 'u-1',
        ),
        rpc: rpc,
      );
    }

    void expectSingleCall(RecordingRpc rpc, String fn, Map<String, dynamic> params) {
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'partner');
      expect(rpc.calls.single.fn, fn);
      expect(rpc.calls.single.params, params);
    }

    const writeRow = [
      {
        'partner_id': 'p-1',
        'expected_version': 9,
        'organization_partner_id': 'org-1',
        'person_partner_id': 'per-1',
      },
    ];

    test('create_partner: cá nhân đủ trường kèm invoice + delivery', () async {
      final t = make((_, _) => writeRow);
      await t.repo.create(
        partnerType: PartnerType.person,
        roles: const [PartnerRoleType.customer, PartnerRoleType.supplier],
        personProfile: person(),
      );
      expectSingleCall(t.rpc, 'create_partner', kCreatePersonParams);
    });

    test('create_partner: tổ chức businessHousehold kèm người liên hệ chính', () async {
      final t = make((_, _) => writeRow);
      await t.repo.create(
        partnerType: PartnerType.organization,
        roles: const [PartnerRoleType.supplier],
        organizationProfile: organization,
        organizationPrimaryContact: contact,
        confirmDuplicate: true,
      );
      expectSingleCall(t.rpc, 'create_partner', kCreateOrgParams);
    });

    test('update_partner: cá nhân / tổ chức', () async {
      var t = make((_, _) => writeRow);
      await t.repo.update(
        partnerId: 'p-1',
        expectedVersion: 3,
        roles: const [PartnerRoleType.customer],
        personProfile: person(),
      );
      expectSingleCall(t.rpc, 'update_partner', kUpdatePersonParams);

      t = make((_, _) => writeRow);
      await t.repo.update(
        partnerId: 'p-2',
        expectedVersion: 5,
        roles: const [PartnerRoleType.customer, PartnerRoleType.supplier],
        organizationProfile: organization,
        confirmDuplicate: true,
      );
      expectSingleCall(t.rpc, 'update_partner', kUpdateOrgParams);
    });

    test('transform_to_organization', () async {
      final t = make((_, _) => writeRow);
      await t.repo.transformToOrganization(
        partnerId: 'p-1',
        expectedVersion: 4,
        organizationProfile: organization,
      );
      expectSingleCall(t.rpc, 'transform_to_organization', kTransformParams);
    });

    test('add_organization_contact: chọn có sẵn / tạo mới', () async {
      var t = make((_, _) => writeRow);
      await t.repo.addContact(organizationPartnerId: 'org-1', personPartnerId: 'per-1');
      expectSingleCall(t.rpc, 'add_organization_contact', kAddContactExistingParams);

      t = make((_, _) => writeRow);
      await t.repo.addContact(
        organizationPartnerId: 'org-1',
        newPersonProfile: contact,
        contactRole: 'Kế toán',
        isPrimary: true,
      );
      expectSingleCall(t.rpc, 'add_organization_contact', kAddContactNewParams);
    });

    test('update_organization_contact / remove_organization_contact', () async {
      var t = make((_, _) => null);
      await t.repo.updateContact(
        organizationPartnerId: 'org-1',
        personPartnerId: 'per-1',
        contactRole: 'Giám đốc',
        isPrimary: true,
        note: 'ghi chú',
        personProfile: person(),
      );
      expectSingleCall(t.rpc, 'update_organization_contact', kUpdateContactParams);

      t = make((_, _) => null);
      await t.repo.removeContact(organizationPartnerId: 'org-1', personPartnerId: 'per-1');
      expectSingleCall(t.rpc, 'remove_organization_contact', kRemoveContactParams);
    });

    test('deactivate / reactivate / soft_delete: có reason', () async {
      final calls = <(String, Future<Object?> Function(PartnerRepository))>[
        (
          'deactivate_partner',
          (r) => r.deactivate('p-1', expectedVersion: 2, reason: 'Không còn giao dịch'),
        ),
        (
          'reactivate_partner',
          (r) => r.reactivate('p-1', expectedVersion: 2, reason: 'Không còn giao dịch'),
        ),
        (
          'soft_delete_partner',
          (r) => r.softDelete('p-1', expectedVersion: 2, reason: 'Không còn giao dịch'),
        ),
      ];
      for (final (fn, run) in calls) {
        final t = make((_, _) => writeRow);
        await run(t.repo);
        expectSingleCall(t.rpc, fn, kStatusParams);
      }
    });

    test('search_partners: both / any / role / không lọc', () async {
      var t = make((_, _) => [kSearchJson]);
      await t.repo.search(
        query: 'abc',
        partnerType: PartnerType.organization,
        role: PartnerRoleType.customer,
        requireBothRoles: true,
        status: PartnerStatus.active,
        updatedWithinDays: 30,
        page: 2,
        limit: 40,
        sort: 'name_asc',
      );
      expectSingleCall(t.rpc, 'search_partners', kSearchBothParams);

      t = make((_, _) => [kSearchJson]);
      await t.repo.search(requireAnyRole: true, status: PartnerStatus.active, limit: 30);
      expectSingleCall(t.rpc, 'search_partners', kSearchAnyParams);

      t = make((_, _) => [kSearchJson]);
      await t.repo.search(
        partnerType: PartnerType.person,
        role: PartnerRoleType.supplier,
        requireAnyRole: true,
      );
      expectSingleCall(t.rpc, 'search_partners', kSearchRoleParams);

      t = make((_, _) => [kSearchJson]);
      await t.repo.search();
      expectSingleCall(t.rpc, 'search_partners', kSearchPlainParams);
    });

    test('get_partner_detail / check_duplicate / check_delete_eligibility', () async {
      var t = make((_, _) => kOrgDetailJson);
      await t.repo.getDetail('p-1');
      expectSingleCall(t.rpc, 'get_partner_detail', kDetailParams);

      t = make((_, _) => kDuplicateRows);
      await t.repo.checkDuplicates(
        phone: '0901234567',
        email: 'a@example.com',
        taxCode: '0101234567',
        name: 'Nguyễn Văn A',
        excludePartnerId: 'p-9',
      );
      expectSingleCall(t.rpc, 'check_duplicate', kDuplicateParams);

      t = make(
        (_, _) => [
          {'eligible': true},
        ],
      );
      await t.repo.checkDeleteEligibility('p-1');
      expectSingleCall(t.rpc, 'check_delete_eligibility', kDetailParams);
    });

    test('đọc detail tổ chức / cá nhân', () async {
      var t = make((_, _) => kOrgDetailJson);
      expect(describeDetail(await t.repo.getDetail('p-org')), kOrgDetailExpected);
      t = make((_, _) => kPersonDetailJson);
      expect(describeDetail(await t.repo.getDetail('p-per')), kPersonDetailExpected);
    });

    test('đọc search: thiếu total/page/limit, kết quả {} và không có dòng', () async {
      var t = make((_, _) => [kSearchJson]);
      expect(describeSearch(await t.repo.search()), kSearchExpected);
      t = make((_, _) => [<String, dynamic>{}]);
      expect(describeSearch(await t.repo.search()), kSearchEmptyExpected);
      t = make((_, _) => <Object>[]);
      expect(describeSearch(await t.repo.search()), kSearchEmptyExpected);
    });

    test('đọc duplicate: tax_code/name/phone/email và mức khớp', () async {
      final t = make((_, _) => kDuplicateRows);
      expect(describeDuplicates(await t.repo.checkDuplicates()), kDuplicateExpected);
    });

    test('đọc delete eligibility', () async {
      var t = make(
        (_, _) => [
          {'eligible': false, 'reason': 'Có giao dịch'},
        ],
      );
      var dto = await t.repo.checkDeleteEligibility('p-1');
      expect(dto.eligible, isFalse);
      expect(dto.reason, 'Có giao dịch');
      t = make(
        (_, _) => [
          {'eligible': true},
        ],
      );
      dto = await t.repo.checkDeleteEligibility('p-1');
      expect(dto.eligible, isTrue);
      expect(dto.reason, isNull);
    });

    test('đọc kết quả ghi: create / update / transform / add contact / status', () async {
      var t = make(
        (_, _) => [
          {
            'partner_id': 'p-1',
            'warnings': [
              {'code': 'DUPLICATE_WARNING', 'message': 'm', 'field': 'phone'},
              {'code': 'X'},
            ],
          },
        ],
      );
      final created = await t.repo.create(
        partnerType: PartnerType.person,
        roles: const [PartnerRoleType.customer],
        personProfile: person(),
      );
      expect(created.partnerId, 'p-1');
      expect(describeWarnings(created), {'DUPLICATE_WARNING/phone': 'm', 'X/null': ''});

      t = make(
        (_, _) => [
          {'partner_id': 'p-1', 'expected_version': 4, 'warnings': null},
        ],
      );
      final updated = await t.repo.update(
        partnerId: 'p-1',
        expectedVersion: 3,
        roles: const [PartnerRoleType.customer],
        personProfile: person(),
      );
      expect(updated.partnerId, 'p-1');
      expect(updated.expectedVersion, 4);
      expect(updated.warnings, isEmpty);

      t = make(
        (_, _) => [
          {'partner_id': 'p-9'},
        ],
      );
      expect(
        await t.repo.transformToOrganization(
          partnerId: 'p-1',
          expectedVersion: 1,
          organizationProfile: organization,
        ),
        'p-9',
      );

      t = make(
        (_, _) => [
          {'organization_partner_id': 'org-1', 'person_partner_id': 'per-1'},
        ],
      );
      final contactResult = await t.repo.addContact(
        organizationPartnerId: 'org-1',
        personPartnerId: 'per-1',
      );
      expect(contactResult.organizationPartnerId, 'org-1');
      expect(contactResult.personPartnerId, 'per-1');

      for (final run in <Future<dynamic> Function(PartnerRepository)>[
        (r) => r.deactivate('p-1', expectedVersion: 1),
        (r) => r.reactivate('p-1', expectedVersion: 1),
        (r) => r.softDelete('p-1', expectedVersion: 1),
      ]) {
        t = make(
          (_, _) => [
            {'partner_id': 'p-1', 'expected_version': 6},
          ],
        );
        final r = await run(t.repo);
        expect(r.partnerId, 'p-1');
        expect(r.expectedVersion, 6);
      }
    });
  });
}
