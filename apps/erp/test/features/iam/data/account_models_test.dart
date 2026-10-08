import 'package:erp/features/iam/data/models/my_account.dart';
import 'package:erp/features/iam/data/models/password_reset_result.dart';
import 'package:erp/features/iam/data/models/tenant_profile.dart';
import 'package:erp/features/iam/data/models/upsert_legal_profile_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  test('MyAccount maps profile columns and keeps identity aliases', () {
    final account = MyAccount.fromProfileRow(
      {
        'user_id': 'user-1',
        'given_name': 'Lan',
        'family_middle_name': 'Le',
        'phone_number': '0901',
        'avatar_reference': 'avatars/lan.png',
      },
      email: 'lan@gmail.com',
      emailVerified: true,
    );

    expect(account.userId, 'user-1');
    expect(account.givenName, 'Lan');
    expect(account.familyName, 'Le');
    expect(account.firstName, 'Lan');
    expect(account.lastName, 'Le');
    expect(account.phone, '0901');
    expect(account.emailVerified, isTrue);
    expect(account.avatarReference, 'avatars/lan.png');
    expect(account.fullName, 'Le Lan');
  });

  test('TenantProfile maps contact fields and legal profile', () {
    final profile = TenantProfile.fromJson({
      'tenant_id': 'org-001',
      'display_name': 'Mậu Hiên',
      'status': 'active',
      'version': 2,
      'business_timezone': 'Asia/Ho_Chi_Minh',
      'base_currency_code': 'VND',
      'created_at': '2026-07-10T10:00:00Z',
      'updated_at': '2026-07-12T16:00:00Z',
      'contact_email': 'contact@mauhien.vn',
      'contact_phone': '0901',
      'legal_profile': {
        'tenant_id': 'org-001',
        'legal_entity_type': 'ENTERPRISE',
        'legal_name': 'Mậu Hiên Co',
        'tax_code': '0123456789',
        'version': 1,
        'created_at': '2026-07-11T00:00:00Z',
        'updated_at': '2026-07-11T00:00:00Z',
      },
    });

    expect(profile.displayName, 'Mậu Hiên');
    expect(profile.status, TenantLifecycleStatus.active);
    expect(profile.version, 2);
    expect(profile.legalProfile?.legalEntityType, LegalEntityType.enterprise);
    expect(profile.legalProfile?.taxCode, '0123456789');
  });

  test('UpsertLegalProfileResult maps a duplicate-tax warning', () {
    final result = UpsertLegalProfileResult.fromJson({
      'tenant_version': 3,
      'warning': {
        'code': 'DUPLICATE_TAX_CODE_WARNING',
        'message': 'trùng',
      },
    });

    expect(result.isWarning, isTrue);
    expect(result.warning?.message, 'trùng');
    expect(result.tenantVersion, 3);
  });

  test('maskEmail hides the local part', () {
    expect(maskEmail('lan@gmail.com'), 'l***@gmail.com');
    expect(maskEmail('invalid'), '***');
  });
}
