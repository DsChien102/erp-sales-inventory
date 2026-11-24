// 4-A, H3: rule domain chạy trước RPC create / update / transform.
//
// `partner_rules.dart`: bảng ca giữ nguyên hành vi của module cũ (đã xoá ở 4-C).
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/partner/data/models/partner_enums.dart';
import 'package:erp/features/partner/data/models/partner_inputs.dart';
import 'package:erp/features/partner/logic/partner_rules.dart';
import 'package:flutter_test/flutter_test.dart';

PersonProfileInput _newPerson({
  String fullName = 'Nguyễn Văn A',
  String phone = '0901234567',
  String? phone2,
  String? email,
  String? taxCode,
  String? invoiceEmail,
}) => PersonProfileInput(
  fullName: fullName,
  phone: phone,
  phone2: phone2,
  email: email,
  taxCode: taxCode,
  invoice: invoiceEmail == null ? null : InvoiceProfileInput(invoiceEmail: invoiceEmail),
);

OrganizationProfileInput _newOrg({
  String name = 'Công ty A',
  String phone = '0281234567',
  String? email,
  String? taxCode,
  String? invoiceEmail,
}) => OrganizationProfileInput(
  organizationType: OrganizationType.company,
  organizationName: name,
  phone: phone,
  email: email,
  taxCode: taxCode,
  invoice: invoiceEmail == null ? null : InvoiceProfileInput(invoiceEmail: invoiceEmail),
);

Matcher _validation([String? message]) => throwsA(
  isA<AppException>()
      .having((e) => e.code, 'code', AppErrorCode.validation)
      .having((e) => e.serverMessage, 'serverMessage', message ?? isNotNull),
);

void main() {
  group('PartnerRules (H3)', () {
    test('hồ sơ cá nhân hợp lệ không ném', () {
      expect(() => PartnerRules.checkPersonProfile(_newPerson()), returnsNormally);
    });

    test('SĐT: 7 số sai, 8 và 15 số đúng, 16 số sai', () {
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(phone: '1234567')),
        _validation('Phone format is invalid'),
      );
      expect(() => PartnerRules.checkPersonProfile(_newPerson(phone: '12345678')), returnsNormally);
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(phone: '123456789012345')),
        returnsNormally,
      );
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(phone: '1234567890123456')),
        _validation('Phone format is invalid'),
      );
    });

    test('SĐT đếm chữ số sau khi bỏ ký tự khác; rỗng sai', () {
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(phone: '090 123 4567')),
        returnsNormally,
      );
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(phone: '   ')),
        _validation('Phone is required'),
      );
    });

    test('phone2 khác null phải theo cùng luật', () {
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(phone2: '123')),
        _validation('Phone format is invalid'),
      );
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(phone2: '0907654321')),
        returnsNormally,
      );
    });

    test('email: a@b sai, a@b.c đúng, rỗng không bị rule email chặn', () {
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(email: 'a@b')),
        _validation('Email format is invalid'),
      );
      expect(() => PartnerRules.checkPersonProfile(_newPerson(email: 'a@b.c')), returnsNormally);
      expect(() => PartnerRules.checkPersonProfile(_newPerson(email: '')), returnsNormally);
    });

    test('MST khác null mà chỉ khoảng trắng sai', () {
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(taxCode: '  ')),
        _validation('Tax code must not be blank when provided'),
      );
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(taxCode: '0101234567')),
        returnsNormally,
      );
    });

    test('email hoá đơn sai', () {
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(invoiceEmail: 'x@y')),
        _validation('Email format is invalid'),
      );
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(invoiceEmail: 'x@y.vn')),
        returnsNormally,
      );
    });

    test('họ tên chỉ khoảng trắng sai', () {
      expect(
        () => PartnerRules.checkPersonProfile(_newPerson(fullName: '   ')),
        _validation('Display name must not be blank'),
      );
    });

    test('tổ chức: tên rỗng, SĐT, email, MST, email hoá đơn', () {
      expect(() => PartnerRules.checkOrganizationProfile(_newOrg()), returnsNormally);
      expect(
        () => PartnerRules.checkOrganizationProfile(_newOrg(name: ' ')),
        _validation('Display name must not be blank'),
      );
      expect(
        () => PartnerRules.checkOrganizationProfile(_newOrg(phone: '12')),
        _validation('Phone format is invalid'),
      );
      expect(
        () => PartnerRules.checkOrganizationProfile(_newOrg(email: 'a@b')),
        _validation('Email format is invalid'),
      );
      expect(
        () => PartnerRules.checkOrganizationProfile(_newOrg(taxCode: ' ')),
        _validation('Tax code must not be blank when provided'),
      );
      expect(
        () => PartnerRules.checkOrganizationProfile(_newOrg(invoiceEmail: 'x@y')),
        _validation('Email format is invalid'),
      );
    });

    test('roles rỗng sai', () {
      expect(
        () => PartnerRules.checkRoles(const []),
        _validation('Partner must have at least one role'),
      );
      expect(() => PartnerRules.checkRoles(const [PartnerRoleType.customer]), returnsNormally);
    });

    test('loại cá nhân thiếu hồ sơ cá nhân sai', () {
      expect(() => PartnerRules.checkProfileMatchesType(PartnerType.person), _validation());
    });

    test('loại tổ chức có cả hai hồ sơ sai; đúng một hồ sơ khớp thì được', () {
      expect(
        () => PartnerRules.checkProfileMatchesType(
          PartnerType.organization,
          person: _newPerson(),
          organization: _newOrg(),
        ),
        _validation(),
      );
      expect(
        () =>
            PartnerRules.checkProfileMatchesType(PartnerType.organization, organization: _newOrg()),
        returnsNormally,
      );
      expect(
        () => PartnerRules.checkProfileMatchesType(PartnerType.person, organization: _newOrg()),
        _validation(),
      );
    });
  });
}
